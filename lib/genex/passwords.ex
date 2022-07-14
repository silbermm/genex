defmodule Genex.Passwords do
  @moduledoc """
  Handles encrypting, decrypting, reading and saving passwords
  """

  alias Genex.AppConfig
  alias Genex.Passwords.Password

  require Logger

  @store Application.compile_env!(:genex, :store)

  @doc """
  Encrypt a password and save it to the DB
  """
  @spec save(Password.t(), Diceware.Passphrase.t()) :: :ok | {:error, binary()}
  def save(%Password{} = password, %Diceware.Passphrase{} = passphrase) do
    # get config
    case Genex.AppConfig.read() do
      {:ok, %AppConfig{gpg_email: gpg_email}} when gpg_email != "" ->
        Logger.debug("Encrypting password for #{gpg_email}")

        # encode the passphrase
        encoded = Jason.encode!(passphrase)

        # encrypt passphrase
        {:ok, encrypted} = GPG.encrypt(gpg_email, encoded)

        # add the encrtyped passphrase to the password
        password = Password.add_passphrase(password, encrypted)

        # save the password in storage
        @store.save_password(password)

        Logger.debug("Password saved")

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
end
