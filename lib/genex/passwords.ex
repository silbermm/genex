defmodule Genex.Passwords do
  @moduledoc """
  Handles encrypting, decrypting, reading and saving passwords
  """

  alias Genex.AppConfig
  alias Genex.Passwords.Password

  @spec save(Password.t(), Diceware.Passphrase.t()) :: :ok | {:error, binary()}
  def save(%Password{} = password, %Diceware.Passphrase{} = passphrase) do
    # get config
    case Genex.AppConfig.read() do
      {:ok, %AppConfig{gpg_email: gpg_email}} when gpg_email != "" ->

        #encode the passphrase
        encoded = Jason.encode!(passphrase)

        # encrypt passphrase
        {:ok, encrypted} = GPG.encrypt(gpg_email, encoded)

        #add the encrtyped passphrase to the password
        password = Password.add_passphrase(password, encrypted)

        IO.inspect password

        # save the password in storage

        :ok

      {:ok, _} ->
        {:error, :no_gpg_email}

      err ->
        err
    end
  end
end
