defmodule Genex.Encryption.RSA do
  @moduledoc """
  Encryption and Decryption using RSA
  """

  alias Genex.Encryption
  alias Genex.Data.Credentials

  @behaviour Genex.Encryption

  @private_key_file Application.get_env(:genex, :private_key)
  @public_key_file Application.get_env(:genex, :public_key)

  @impl Encryption
  def encrypt(data) do
    with {:ok, raw_public_key} <- File.read(@public_key_file),
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
    try do
      {:ok, private_key} = get_key(@private_key_file, password)
      data = :base64.decode(data)
      {:ok, :public_key.decrypt_private(data, private_key)}
    rescue
      _e in _ ->
        {:error, "Unable to decrypt"}
    end
  end

  @impl true
  def decrypt_credentials(creds, password \\ nil) do
    {:ok, private_key} = get_key(@private_key_file, password)
    data = :base64.decode(creds.encrypted_password)
    data_username = :base64.decode(creds.encrypted_username)
    pass = :public_key.decrypt_private(data, private_key)
    username = :public_key.decrypt_private(data_username, private_key)

    creds
    |> Credentials.add_password(pass)
    |> Credentials.add_username(username)
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

        _ ->
          {:error, :noloadkey}
      end
    else
      error -> error
    end
  end
end
