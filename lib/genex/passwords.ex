defmodule Genex.Passwords do
  @moduledoc """
  Handles encrypting, decrypting, reading and saving passwords
  """

  import Ecto.Query

  alias Genex.AppConfig
  alias Genex.Passwords.Password
  alias Genex.Passwords.PasswordData
  alias Genex.Repo

  require Logger

  @store Application.compile_env!(:genex, :store)

  @doc """
  Generate a unique password
  """
  @spec generate(integer()) :: Diceware.Passphrase.t()
  def generate(count) do
    Diceware.generate(count: count)
  end

  @typep save_result ::
           {:ok, PasswordData.t()} | {:error, binary()} | {:error, Ecto.Changeset.t()}

  @doc """
  Encrypt a password and save it to the DB
  """
  @spec save(String.t(), String.t(), Diceware.Passphrase.t(), map()) :: save_result()
  def save(account, username, %Diceware.Passphrase{} = passphrase, %{
        gpg: %{"email" => gpg_email}
      })
      when gpg_email != "" do
    Logger.debug("Encrypting password for #{gpg_email}")

    # encode the passphrase
    encoded = Jason.encode!(passphrase)

    # encrypt passphrase
    case GPG.encrypt(gpg_email, encoded) do
      {:ok, encrypted} ->
        # add the encrypted passphrase to the password
        # build the changeset and try to save it
        %PasswordData{}
        |> PasswordData.changeset(%{
          username: username,
          account: account,
          encrypted_password: encrypted
        })
        |> Repo.insert()

      err ->
        err
    end
  end

  @doc """
  Encrypt a password and save it to the DB
  """
  @spec save(String.t(), String.t(), Diceware.Passphrase.t()) :: save_result()
  def save(account, username, %Diceware.Passphrase{} = passphrase) do
    # get config
    case AppConfig.read() do
      {:ok, %{gpg: %{"email" => gpg_email}} = config} when gpg_email != "" ->
        save(account, username, passphrase, config)

      {:ok, _} ->
        {:error, :no_gpg_email}

      err ->
        err
    end
  end

  @doc """
  Get all passwords that do not have a deleted_on date
  """
  @spec all :: {:ok, [PasswordData.t()]} | {:error, binary()}
  def all() do
    query = from(p in PasswordData, where: is_nil(p.deleted_at))
    Repo.all(query)
  end

  @doc """
  Decrypt the encrypted password field from PasswordData
  """
  @spec decrypt(PasswordData.t()) :: {:ok, Diceware.Passphrase.t()} | {:error, binary()}
  def decrypt(%PasswordData{encrypted_password: encrypted_password}) do
    case GPG.decrypt(encrypted_password) do
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
  Deletes a password from the store

  Functionally this removes the encrypted password column and
  adds the deleted_at field.

  Doing this allows us to know if we need to sync the password
  or not.
  """
  @spec delete(PasswordData.t()) :: {:ok, number()} | {:error, binary()}
  def delete(password) do
    password
    |> PasswordData.delete_changeset()
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, updated.id}
      err -> err
    end
  end

  @doc """
  Find a password by the account name
  """
  @spec find_by_account(String.t()) :: {:ok, [PasswordData.t()]} | {:error, binary()}
  def find_by_account(account) do
    query = from p in PasswordData, where: p.account == ^account
    Repo.all(query)
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
         {:ok, pword_list} <- Jason.decode(decrypted) do
      # as_password_list <- Enum.map(pword_list, &convert_to_password/1) do
      Logger.info(inspect(pword_list))
      _ = merge(pword_list)
      all()
    else
      {:ok, ""} -> all()
      err -> err
    end
  end

  # defp convert_to_password(map) do
  #   %PasswordData{}
  #   |> PasswordData.changeset(map)
  #   |> Ecto.Changeset.apply_changes()
  # end

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
        with {:ok, pwords_for_account} <- find_by_account(Map.get(remote_password, "account")),
             local_password when not is_nil(local_password) <-
               Enum.find(
                 pwords_for_account,
                 &(&1.username == Map.get(remote_password, "username"))
               ),
             :gt <-
               DateTime.compare(Map.get(remote_password, "updated_at"), local_password.updated_at) do
          case delete_or_save(remote_password, local_password) do
            :delete ->
              delete(local_password)

            :save ->
              Logger.debug("Saving password for #{remote_password.account}")

              local_password
              |> PasswordData.changeset(
                Map.drop(remote_password, ["inserted_at", "updated_at", "id"])
              )
              |> Repo.update()
          end
        else
          nil ->
            Logger.debug("Saving password for #{remote_password.account}")

            %PasswordData{}
            |> PasswordData.changeset(remote_password)
            |> Repo.insert()

          other ->
            Logger.debug("NOT saving password for #{inspect(other)}")
            :ok
        end
      end
    end
  end

  # if both passwords are not deleted, save the password
  defp delete_or_save(
         %{deleted_at: nil} = _remote_password,
         %PasswordData{deleted_at: nil} = _current_password
       ),
       do: :save

  # if the remote has a deleted on and the local doesn't
  # check the local's created_on is greater than the remote
  # deleted_on and if it is, :save, if not :delete
  defp delete_or_save(
         %{deleted_at: %DateTime{} = remote_deleted_at} = _remote_password,
         %PasswordData{deleted_at: nil} = local_password
       ) do
    case DateTime.compare(remote_deleted_at, local_password.updated_at) do
      :gt -> :delete
      _ -> :save
    end
  end

  # if the local has a deleted on and the remote doesn't
  # check if the remote's created_on is greater than the local's
  # deleted_on and if it is, :save, if not :delete
  defp delete_or_save(
         %{deleted_at: nil, updated_at: updated_at} = _remote_password,
         %PasswordData{deleted_at: %DateTime{} = local_deleted_at} = _local_password
       ) do
    case DateTime.compare(updated_at, local_deleted_at) do
      :gt -> :save
      _ -> :delete
    end
  end

  # if they both have a deleted on, do nothing
  defp delete_or_save(
         %{deleted_at: %DateTime{}} = _remote_password,
         %PasswordData{deleted_at: %DateTime{}} = _local_password
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
