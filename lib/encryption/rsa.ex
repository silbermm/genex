defmodule Genex.Encryption.RSA do
  @moduledoc """
  Encryption and Decryption using RSA
  """

  alias Genex.Encryption

  @behavior @Encryption

  @doc """
  Load the genex RSA encrypted file into memory. If the file doesn't exist, returns an error
  """
  @impl Encryption
  def load(password \\ nil) do
    filename = System.get_env("HOME") <> "/" <> ".genex_passwords.rsa"
    keyfile = System.get_env("HOME") <> "/" <> ".genex/genex_private.pem"

    with {:ok, file_contents} <- File.read(filename),
         {:ok, private_key} <- get_key(keyfile, password) do
      try do
        {:ok, :public_key.decrypt_private(file_contents, private_key)}
      rescue
        e in ErlangError -> {:error, "Unable to decrypt"}
      end
    else
      {:error, :nokeydecrypt} = e -> e
      {:error, :noloadkey} = e -> e
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
        {:error, "Unable to save to encrypted file"}
    end
  end

  defp get_key(key_file, password) do
    with {:ok, raw_key} <- File.read(key_file),
         [enc_key] = :public_key.pem_decode(raw_key) do
      key = case enc_key do
        {_, _, :not_encrypted} = res -> {:ok, :public_key.pem_entry_decode(res)}
        {keytype, _, _} = res ->
          try do
            der = :pubkey_pem.decipher(res, password)
            {:ok, :public_key.der_decode(keytype, der)}
          rescue
            e in _ -> {:error, :nokeydecrypt}
          end
        _ ->
          {:error, :noloadkey}
      end
    else
      error -> error
    end
  end
end
