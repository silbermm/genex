defmodule Genex.Passwords do
  @moduledoc """
  Handles encryption, decryption, reading and saving passwords
  """

  alias Genex.Store.Secret
  alias Genex.Store.Settings
  alias Genex.Store
  alias Diceware.Passphrase

  require Logger

  @typep save_result :: {:ok, Secret.t()} | {:error, binary()}

  @doc """
  Generate a unique password
  """
  @spec generate(integer()) :: Passphrase.t()
  def generate(count), do: Diceware.generate(count: count)

  @doc """
  Encrypt a password and save it to the DB

  Options include:
    * action    (defaults to :insert)
  """
  @spec save(String.t(), Passphrase.t(), Settings.t(), Keyword.t()) :: save_result()
  def save(key, %Passphrase{} = passphrase, %Settings{} = settings, opts \\ []) do
    action = Keyword.get(opts, :action, :insert)

    Logger.debug("Encrypting password for #{settings.gpg_email}")

    # hash the passphrase
    hash = :erlang.phash2(passphrase)

    # encode the passphrase
    encoded = Diceware.encode(passphrase)

    # encrypt passphrase
    case GPG.encrypt(settings.gpg_email, encoded) do
      {:ok, encrypted} ->
        secret =
          key
          |> Secret.new(hash, encrypted)
          |> Secret.set_action(action)
          |> Secret.set_profile(settings.profile)

        # save the encrypted passphrase
        Store.for(:secrets).create(secret)

      err ->
        err
    end
  end

  @doc """
  List all of the active passwords.

  Options
    * profile  (defaults to "default")
  """
  @spec all(Keyword.t()) :: [Secret.t()]
  def all(opts \\ []) do
    profile = Keyword.get(opts, :profile, "default")

    :secrets
    |> Store.for()
    |> then(& &1.find_by(:profile, profile))
    |> group_by_key()
    |> only_latest()
    |> drop_deleted()
  end

  @doc """
  Decrypt the encrypted password
  """
  @spec decrypt(Secret.t()) :: {:ok, Passphrase.t()} | {:error, binary()}
  def decrypt(%Secret{encrypted_password: encrypted_password}) do
    case GPG.decrypt(encrypted_password) do
      {:ok, password} ->
        {:ok, Diceware.decode(password)}

      e ->
        e
    end
  end

  @doc """
  Deletes a password from the store

  Functionally this adds a new row to the database with a deleted action for this password.
  This allows us to track the lifecycle of a password.
  """
  @spec delete(Secret.t(), keyword()) :: save_result() | no_return()
  def delete(secret, opts \\ []) do
    case decrypt(secret) do
      {:ok, passphrase} ->
        opts = Keyword.put(opts, :action, :delete)
        save(secret.key, passphrase, opts)

      e ->
        e
    end
  end

  @doc """
  Find a password by the saved key
  """
  @spec find_by_key(String.t(), String.t()) :: [Secret.t()]
  def find_by_key(key, profile \\ "default") do
    :secrets
    |> Store.for()
    |> then(& &1.find_by(:key, key))
    |> Enum.reject(&(&1.profile != profile))
    |> group_by_key()
    |> only_latest()
    |> drop_deleted()
  end

  defp group_by_key(passwords), do: Enum.group_by(passwords, & &1.key)

  defp only_latest(passwords) do
    for {_key, vals} <- passwords do
      vals
      |> Enum.sort_by(& &1.timestamp, {:asc, DateTime})
      |> List.last()
    end
  end

  defp drop_deleted(passwords), do: Enum.reject(passwords, &(&1.action == :delete))
end
