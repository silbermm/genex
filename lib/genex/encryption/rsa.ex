defmodule Genex.Encryption.RSA do
  @moduledoc """
  Encryption and Decryption using RSA
  """

  alias Genex.Encryption
  @behaviour Genex.Encryption

  @impl Encryption
  def local_public_key() do
    public_key_file = Application.get_env(:genex, :genex_home) <> "/public_key.pem"
    File.read!(public_key_file)
  end

  @impl Encryption
  def encrypt(data) do
    with raw_public_key <- local_public_key(),
         [enc_public_key] <- :public_key.pem_decode(raw_public_key),
         public_key <- :public_key.pem_entry_decode(enc_public_key) do
      enc_data =
        data
        |> :public_key.encrypt_public(public_key)
        |> :base64.encode()

      {:ok, enc_data}
    else
      _ -> {:error, "Unable to encrypt data"}
    end
  end

  @impl Encryption
  def encrypt(data, public_key_path) do
    with {:ok, raw_public_key} <- File.read(public_key_path),
         [enc_public_key] <- :public_key.pem_decode(raw_public_key),
         public_key <- :public_key.pem_entry_decode(enc_public_key) do
      enc_data =
        data
        |> :public_key.encrypt_public(public_key)
        |> :base64.encode()

      {:ok, enc_data}
    else
      _ -> {:error, "Unable to save to encrypted file"}
    end
  end

  @impl Encryption
  def decrypt(data, password \\ nil) do
    private_key_file = Application.get_env(:genex, :genex_home) <> "/private_key.pem"

    with {:ok, private_key} <- get_key(private_key_file, password),
         data <- :base64.decode(data) do
      :public_key.decrypt_private(data, private_key)
    else
      {:error, :nokeydecrypt} -> raise "nokeydecrypt"
    end
  rescue
    _e -> :error
  end

  defp get_key(key_file, password) do
    with {:ok, raw_key} <- File.read(key_file),
         [enc_key] <- :public_key.pem_decode(raw_key) do
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
      end
    else
      error -> error
    end
  end
end
