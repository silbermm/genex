defmodule Genex.Encryption.RSA do
  @moduledoc """
  Encryption and Decryption using RSA
  """

  alias Genex.Encryption

  @behavior @Encryption

  @doc """
  Load the genex RSA encrypted file into memory. If the file doesn't exist, returns an error

  TODO: encrypted private key

  [enc_private_key] = :public_key.pem_decode(raw_private_key)
  der = :pubkey_pem.decipher(res1, passphrase)
  private_key = :public_key.pem_entry_decode(:RSAPrivateKey, der)

  """
  @impl Encryption
  def load do
    filename = System.get_env("HOME") <> "/" <> ".genex_passwords.rsa"
    keyfile = System.get_env("HOME") <> "/" <> ".genex/genex_private.pem"

    with {:ok, file_contents} <- File.read(filename),
         {:ok, raw_private_key} <- File.read(keyfile),
         [enc_private_key] <- :public_key.pem_decode(raw_private_key),
         private_key <- :public_key.pem_entry_decode(enc_private_key) do
      try do
        {:ok, :public_key.decrypt_private(file_contents, private_key)}
      rescue
        e in ErlangError -> {:error, "Unable to decrypt"}
      end
    else
      error -> {:error, :noexists}
    end
  end

  def save(data) do
    filename = System.get_env("HOME") <> "/" <> ".genex_passwords.rsa"
    keyfile = System.get_env("HOME") <> "/" <> ".genex/genex_public.pem"

    with {:ok, raw_public_key} <- File.read(keyfile),
         [enc_public_key] <- :public_key.pem_decode(raw_public_key),
         public_key <- :public_key.pem_entry_decode(enc_public_key) do

      enc_data = :public_key.encrypt_public(data, public_key)
      File.write!(filename, enc_data)
      :ok
    else
      error ->
        IO.inspect error
        {:error, "Unable to save to encrypted file"}
    end
  end

  def generate_keys do

  end
end
