defmodule Genex.Encryption.GPG do
  @moduledoc """
  Deals with all aspects of GnuPG
  """
  alias Genex.Encryption

  @behavior @Encryption

  @doc """
  Load the genex gpg encrypted file into memory. If the file doesn't exist, returns an error.
  """
  @impl Encryption
  def load do
    file = System.get_env("HOME") <> "/" <> ".genex_passwords.gpg"

    with {result, 0} <-
           System.cmd("gpg", ["--decrypt", "--quiet", "--no-tty", "--batch", file, " 2>&1"]) do
      {:ok, result}
    else
      {error, code} ->
        case code do
          2 -> {:error, :noexists}
          _ -> {:error, "unable to decrypt"}
        end
    end
  end

  @doc """
  Save data to the genex password file and encrypt it with GPG.
  """
  @impl Encryption
  def save(data) do
    filename = System.get_env("HOME") <> "/" <> ".genex_passwords.gpg"

    "echo '#{data}' | gpg --quiet --encrypt --armor -r silbermm --no-tty --yes --batch --status-fd --with-colons -o #{
      filename
    }"
    |> String.to_char_list()
    |> :os.cmd()
  end

  @doc """
  Generate a GPG public/private key combination to use when encyrpting/decrypting the genex passwords file.
  """
  def generate_keys do
  end
end
