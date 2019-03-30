defmodule GenexCore.Encryption.RSA do
  @moduledoc """
  Encryption and Decryption using RSA
  """

  alias GenexCore.Encryption
  alias GenexCore.Environment

  @behaviour GenexCore.Encryption

  @private_key_file Application.get_env(:genex_core, :private_key)
  @public_key_file Application.get_env(:genex_core, :public_key)

  @doc """
  Load the genex RSA encrypted file into memory. If the file doesn't exist, returns an error
  """
  @impl Encryption
  def load(password \\ nil) do
    filename = Environment.load_variable("GENEX_PASSWORDS", :passwords_file)
    with {:ok, file_contents} <- File.read(filename),
         {:ok, private_key} <- get_key(@private_key_file, password) do
      try do
        {:ok, :public_key.decrypt_private(file_contents, private_key)}
      rescue
        _e in _ -> {:error, "Unable to decrypt"}
      end
    else
      {:error, :nokeydecrypt} = e -> e
      {:error, :noloadkey} = e -> e
      _ -> {:error, :noexists}
    end
  end

  @doc """
  Save the supplied data to the genex password file, overwritting whats already there
  """
  @impl Encryption
  def save(data) do
    filename = Environment.load_variable("GENEX_PASSWORDS", :passwords_file)

    with {:ok, raw_public_key} <- File.read(@public_key_file),
         [enc_public_key] <- :public_key.pem_decode(raw_public_key),
         public_key <- :public_key.pem_entry_decode(enc_public_key) do
      enc_data = :public_key.encrypt_public(data, public_key)
      File.write!(filename, enc_data)
      :ok
    else
      _ -> {:error, "Unable to save to encrypted file"}
    end
  end

  defp get_key(key_file, password) do
    with {:ok, raw_key} <- File.read(key_file),
         [enc_key] = :public_key.pem_decode(raw_key) do
      case enc_key do
        {_, _, :not_encrypted} = res ->
          {:ok, :public_key.pem_entry_decode(res)}

        {keytype, _, _} = res ->
          try do
            der = :pubkey_pem.decipher(res, password)
            {:ok, :public_key.der_decode(keytype, der)}
          rescue
            _ in _ -> {:error, :nokeydecrypt}
          end

        _ ->
          {:error, :noloadkey}
      end
    else
      error -> error
    end
  end
end
