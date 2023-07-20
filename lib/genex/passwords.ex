defmodule Genex.Passwords do
  @moduledoc """
  Handles encryption, decryption, reading and saving passwords
  """

  alias Genex.Passwords.Entity
  alias Genex.Settings

  require Logger

  @typep save_result :: {:ok, Entity.t()} | {:error, binary()}

  @doc """
  Generate a unique password
  """
  @spec generate(integer()) :: Diceware.Passphrase.t()
  def generate(count), do: Diceware.generate(count: count)

  @doc """
  Encrypt a password and save it to the DB
  """
  @spec save(String.t(), Diceware.Passphrase.t(), map()) :: save_result()
  def save(key, %Diceware.Passphrase{} = passphrase, %{gpg_email: gpg_email, profile: profile})
      when gpg_email != "" do
    Logger.debug("Encrypting password for #{gpg_email}")

    # hash the passphrase
    hash = :erlang.phash2(passphrase)

    # encode the passphrase
    encoded = Jason.encode!(passphrase)

    # encrypt passphrase
    case GPG.encrypt(gpg_email, encoded) do
      {:ok, encrypted} ->
        key
        |> Entity.new(hash, encrypted)
        |> Entity.set_action(:insert)
        |> Entity.set_profile(profile)
        |> Genex.Store.save()

      err ->
        err
    end
  end

  #   @doc """

  #   """
  #   @spec update(PasswordData.t(), Dicware.Passphrase.t(), map()) :: save_result()
  #   def update(password_data, %Diceware.Passphrase{} = passphrase, %{
  #         gpg_email: gpg_email,
  #         profile: profile
  #       }) do
  #     Logger.debug("Encrypting password for #{gpg_email}")

  #     # encode the passphrase
  #     encoded = Jason.encode!(passphrase)

  #     # encrypt passphrase
  #     case GPG.encrypt(gpg_email, encoded) do
  #       {:ok, encrypted} ->
  #         # add the encrypted passphrase to the password
  #         # build the changeset and try to save it
  #         password_data
  #         |> PasswordData.changeset(%{
  #           encrypted_password: encrypted,
  #           profile: profile
  #         })
  #         |> Repo.update()

  #       err ->
  #         err
  #     end
  #   end

  @doc """
  Get all passwords that are not deleted
  """
  @spec all :: [Entity.t()]
  def all(profile \\ "default") do
    case Genex.Store.find_passwords_by(:profile, "default") do
      {:ok, passwords} ->
        passwords
        |> group_by_key()
        |> only_latest()
        |> drop_deleted()

      err ->
        Logger.error(inspect(err))
        []
    end
  end

  defp group_by_key(passwords), do: Enum.group_by(passwords, & &1.key)

  defp only_latest(passwords) do
    for {key, vals} <- passwords do
      vals
      |> Enum.sort_by(& &1.timestamp, {:asc, DateTime})
      |> List.last()
    end
  end

  defp drop_deleted(passwords), do: Enum.reject(passwords, &(&1.action == :delete))

  #   @doc """
  #   Decrypt the encrypted password field from PasswordData
  #   """
  #   @spec decrypt(PasswordData.t()) :: {:ok, Diceware.Passphrase.t()} | {:error, binary()}
  #   def decrypt(%PasswordData{encrypted_password: encrypted_password}) do
  #     case GPG.decrypt(encrypted_password) do
  #       {:ok, password} ->
  #         {:ok,
  #          password
  #          |> Jason.decode!()
  #          |> Diceware.Passphrase.new()}

  #       e ->
  #         e
  #     end
  #   end

  #   @doc """
  #   Deletes a password from the store

  #   Functionally this removes the encrypted password column and
  #   adds the deleted_at field.

  #   Doing this allows us to know if we need to sync the password
  #   or not.
  #   """
  #   @spec delete(PasswordData.t()) :: {:ok, number()} | {:error, binary()}
  #   def delete(password) do
  #     password
  #     |> PasswordData.delete_changeset()
  #     |> Repo.update()
  #     |> case do
  #       {:ok, updated} -> {:ok, updated.id}
  #       err -> err
  #     end
  #   end

  #   @doc """
  #   Find a password by the account name
  #   """
  #   @spec find_by_account(String.t(), String.t()) :: {:ok, [PasswordData.t()]} | {:error, binary()}
  #   def find_by_account(account, profile \\ "default") do
  #     query = from p in PasswordData, where: p.account == ^account, where: p.profile == ^profile
  #     Repo.all(query)
  #   end

  #   @doc """
  #   Uses the configured api token and host to pull lastest passwords
  #   and merge them into passwords already on the system. 

  #   Newest password wins
  #   """
  #   @spec remote_pull_merge(Settings.Setting.t()) ::
  #           {:ok, [PasswordData.t()]} | {:error, :noexist} | {:error, binary()}
  #   def remote_pull_merge(settings) do
  #     with {:ok, token} <- get_api_key(settings),
  #          url <- settings.remote,
  #          {:ok, passwords} when passwords != "" <- remote_pull(url, token),
  #          {:ok, decrypted} <- GPG.decrypt(passwords),
  #          {:ok, pword_list} <- Jason.decode(decrypted) do
  #       _ = merge(pword_list, settings.profile)
  #       {:ok, all(settings.profile)}
  #     else
  #       {:ok, ""} ->
  #         Logger.debug("remote passwords db empty")
  #         {:ok, all(settings.profile)}

  #       err ->
  #         Logger.debug("error #{inspect(err)}")
  #         err
  #     end
  #   end

  #   def get_api_key(settings \\ nil) do
  #     case settings do
  #       nil ->
  #         {:error, :settings_not_found}

  #       %Settings.Setting{api_key: api_key} when api_key != "" ->
  #         {:ok, api_key}

  #       _ ->
  #         {:error, :api_key_not_found}
  #     end
  #   end

  #   defp remote_pull(nil, _), do: {:error, :invalid_url}

  #   defp remote_pull(url, token) do
  #     case Req.get("#{url}/api/passwords", auth: {:bearer, token}) do
  #       {:ok, res} ->
  #         data = res.body["passwords"]
  #         {:ok, data}

  #       err ->
  #         err
  #     end
  #   end

  #   defp merge(decrypted_passwords, profile) do
  #     for remote_password <- decrypted_passwords do
  #       if !is_nil(remote_password) do
  #         with {:ok, pwords_for_account} <-
  #                find_by_account(Map.get(remote_password, "account"), profile),
  #              local_password when not is_nil(local_password) <-
  #                Enum.find(
  #                  pwords_for_account,
  #                  &(&1.username == Map.get(remote_password, "username"))
  #                ),
  #              :gt <-
  #                DateTime.compare(Map.get(remote_password, "updated_at"), local_password.updated_at) do
  #           case delete_or_save(remote_password, local_password) do
  #             :delete ->
  #               delete(local_password)

  #             :save ->
  #               Logger.debug("Saving password for #{remote_password.account}")

  #               local_password
  #               |> PasswordData.changeset(
  #                 Map.drop(remote_password, ["inserted_at", "updated_at", "id"])
  #               )
  #               |> Repo.update()
  #           end
  #         else
  #           [] ->
  #             Logger.debug("Saving password for #{Map.get(remote_password, "account")}")

  #             %PasswordData{}
  #             |> PasswordData.changeset(remote_password)
  #             |> Repo.insert()

  #           other ->
  #             Logger.debug("NOT saving password for #{inspect(other)}")
  #             :ok
  #         end
  #       end
  #     end
  #   end

  #   # if both passwords are not deleted, save the password
  #   defp delete_or_save(
  #          %{deleted_at: nil} = _remote_password,
  #          %PasswordData{deleted_at: nil} = _current_password
  #        ),
  #        do: :save

  #   # if the remote has a deleted on and the local doesn't
  #   # check the local's created_on is greater than the remote
  #   # deleted_on and if it is, :save, if not :delete
  #   defp delete_or_save(
  #          %{deleted_at: %DateTime{} = remote_deleted_at} = _remote_password,
  #          %PasswordData{deleted_at: nil} = local_password
  #        ) do
  #     case DateTime.compare(remote_deleted_at, local_password.updated_at) do
  #       :gt -> :delete
  #       _ -> :save
  #     end
  #   end

  #   # if the local has a deleted on and the remote doesn't
  #   # check if the remote's created_on is greater than the local's
  #   # deleted_on and if it is, :save, if not :delete
  #   defp delete_or_save(
  #          %{deleted_at: nil, updated_at: updated_at} = _remote_password,
  #          %PasswordData{deleted_at: %DateTime{} = local_deleted_at} = _local_password
  #        ) do
  #     case DateTime.compare(updated_at, local_deleted_at) do
  #       :gt -> :save
  #       _ -> :delete
  #     end
  #   end

  #   # if they both have a deleted on, do nothing
  #   defp delete_or_save(
  #          %{deleted_at: %DateTime{}} = _remote_password,
  #          %PasswordData{deleted_at: %DateTime{}} = _local_password
  #        ) do
  #     :noop
  #   end

  #   @spec remote_push(Settings.Setting.t()) :: :ok | {:error, :noexist}
  #   def remote_push(settings) do
  #     with {:ok, token} <- get_api_key(settings),
  #          url <- settings.remote,
  #          email <- settings.gpg_email do
  #       Genex.Passwords.PasswordPushWorker.start_link(%{url: url, token: token, email: email})
  #     end
  #   end
end
