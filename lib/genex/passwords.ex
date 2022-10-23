defmodule Genex.Passwords do
  @moduledoc """
  Handles encrypting, decrypting, reading and saving passwords
  """

  alias Genex.AppConfig
  alias Genex.Passwords.Password

  require Logger

  @store Application.compile_env!(:genex, :store)

  @doc """
  """
  @spec generate(integer()) :: Diceware.Passphrase.t()
  def generate(count) do
    Diceware.generate(count: count)
  end

  @doc """
  Deletes a password from the store

  Functionally this removes the encrypted password column and
  adds the deleted_on field.

  Doing this allows us to know if we need to sync the password
  or not.
  """
  @spec delete(Password.t()) :: {:ok, number()} | {:error, binary()}
  def delete(password) do
    password
    |> Password.add_deleted_on()
    |> Password.remove_encrypted_passphrase()
    |> @store.update_password()
    |> case do
      :ok -> {:ok, password.id}
      _ -> {:error, :unknown}
    end
  end

  @doc """
  Encrypt a password and save it to the DB
  """
  @spec save(Password.t(), Diceware.Passphrase.t(), map()) :: :ok | {:error, binary()}
  def save(%Password{} = password, %Diceware.Passphrase{} = passphrase, %{
        gpg: %{"email" => gpg_email}
      })
      when gpg_email != "" do
    Logger.debug("Encrypting password for #{gpg_email}")

    # encode the passphrase
    encoded = Jason.encode!(passphrase)

    # encrypt passphrase
    case GPG.encrypt(gpg_email, encoded) do
      {:ok, encrypted} ->
        # add the encrtyped passphrase to the password
        password = Password.add_passphrase(password, encrypted)

        # save the password in storage
        @store.save_password(password)

        Logger.debug("Password saved")
        {:ok, password}

      err ->
        err
    end
  end

  @doc """
  Encrypt a password and save it to the DB
  """
  @spec save(Password.t(), Diceware.Passphrase.t()) :: :ok | {:error, binary()}
  def save(%Password{} = password, %Diceware.Passphrase{} = passphrase) do
    # get config
    case AppConfig.read() do
      {:ok, %{gpg: %{"email" => gpg_email}} = config} when gpg_email != "" ->
        save(password, passphrase, config)

      {:ok, _} ->
        {:error, :no_gpg_email}

      err ->
        err
    end
  end

  @doc """
  Get all passwords
  """
  @spec all :: {:ok, [Password.t()]} | {:error, binary()}
  def all(), do: @store.all_passwords()

  @doc """
  Find a password by the account
  """
  @spec find_by_account(String.t()) :: {:ok, [Password.t()]} | {:error, binary()}
  def find_by_account(account), do: @store.find_password_by(:account, account)

  @spec decrypt(Password.t()) :: {:ok, Diceware.Passphrase.t()} | {:error, binary()}
  def decrypt(%Password{} = password) do
    case GPG.decrypt(password.encrypted_passphrase) do
      {:ok, password} ->
        {:ok,
         password
         |> Jason.decode!()
         |> Diceware.Passphrase.new()}

      e ->
        e
    end
  end

  @doc """
  Uses the configured api token and host to pull lastest passwords
  and merge them into passwords already on the system. 

  Newest password wins
  """
  @spec remote_pull_merge(map()) ::
          {:ok, [Password.t()]} | {:error, :noexist} | {:error, binary()}
  def remote_pull_merge(config) do
    with {:ok, token} <- @store.api_token(),
         url <- get_in(config, [:remote, "url"]),
         {:ok, passwords} when passwords != "" <- remote_pull(url, token),
         {:ok, decrypted} <- GPG.decrypt(passwords),
         {:ok, pword_list} <- Jason.decode(decrypted),
         as_password_list <- Enum.map(pword_list, &Password.new/1) do
      Logger.info(inspect(as_password_list))
      _ = merge(as_password_list)
      all()
    else
      {:ok, ""} -> all()
      err -> err
    end
  end

  defp remote_pull(nil, _), do: {:error, :invalid_url}

  defp remote_pull(url, token) do
    case Req.get("#{url}/api/passwords", auth: {:bearer, token}) do
      {:ok, res} ->
        data = res.body["passwords"]
        {:ok, data}

      err ->
        err
    end
  end

  defp merge(decrypted_passwords) do
    for remote_password <- decrypted_passwords do
      if !is_nil(remote_password) do
        with {:ok, pwords_for_account} <- find_by_account(remote_password.account),
             local_password when not is_nil(local_password) <-
               Enum.find(pwords_for_account, &(&1.username == remote_password.username)),
             :gt <- DateTime.compare(remote_password.timestamp, local_password.timestamp) do
          case delete_or_save(remote_password, local_password) do
            :delete ->
              delete(local_password)

            :save ->
              Logger.debug("Saving password for #{remote_password.account}")
              remote_password = Password.merge(local_password, remote_password)
              @store.update_password(remote_password)
          end
        else
          nil ->
            Logger.debug("Saving password for #{remote_password.account}")
            @store.save_password(remote_password)

          other ->
            Logger.debug("NOT saving password for #{inspect(other)}")
            :ok
        end
      end
    end
  end

  # if both passwords are not deleted, save the password
  defp delete_or_save(
         %Password{deleted_on: nil} = _remote_password,
         %Password{deleted_on: nil} = _current_password
       ),
       do: :save

  # if the remote has a deleted on and the local doesn't
  # check the local's created_on is greater than the remote
  # deleted_on and if it is, :save, if not :delete
  defp delete_or_save(
         %Password{deleted_on: %DateTime{} = remote_deleted_on} = _remote_password,
         %Password{deleted_on: nil} = local_password
       ) do
    case DateTime.compare(remote_deleted_on, local_password.timestamp) do
      :gt -> :delete
      _ -> :save
    end
  end

  # if the local has a deleted on and the remote doesn't
  # check if the remote's created_on is greater than the local's
  # deleted_on and if it is, :save, if not :delete
  defp delete_or_save(
         %Password{deleted_on: nil} = remote_password,
         %Password{deleted_on: %DateTime{} = local_deleted_on} = _local_password
       ) do
    case DateTime.compare(remote_password.timestamp, local_deleted_on) do
      :gt -> :save
      _ -> :delete
    end
  end

  # if they both have a deleted on, do nothing
  defp delete_or_save(
         %Password{deleted_on: %DateTime{}} = _remote_password,
         %Password{deleted_on: %DateTime{}} = _local_password
       ) do
    :noop
  end

  # with %DateTime{} = remote_deleted_on <- remote_password.deleted_on,

  # case DateTime.compare(remote_password.deleted_on, 
  # end

  @spec remote_push(map()) :: :ok | {:error, :noexist}
  def remote_push(config) do
    with {:ok, token} <- @store.api_token(),
         url <- get_in(config, [:remote, "url"]),
         email <- get_in(config, [:gpg, "email"]) do
      Genex.Passwords.PasswordPushWorker.start_link(%{url: url, token: token, email: email})
    end
  end
end
