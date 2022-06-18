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

      {:ok, _} ->
        {:error, :no_gpg_email}

      err ->
        err
    end
  end

  @doc """
  Get all passwords
  """
  @spec all :: {:ok, [Genex.Passwords.Password.t()]} | {:error, binary()}
  def all(), do: @store.all_passwords()
end
