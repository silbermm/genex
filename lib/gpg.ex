defmodule Genex.GPG do
  @moduledoc """
  Deals with all aspects of GnuPG
  """

  @doc """
  Load a gpg encrypted file into memory
  """
  def load do
    file = System.get_env("HOME") <> "/" <> ".genex_passwords.gpg"

    with {result, 0} <- System.cmd("gpg", ["--decrypt", "--quiet", "--no-tty", "--batch", file]) do
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
  Save data to a file and encrypt it with GPG
  """
  def save(data) do
    filename = System.get_env("HOME") <> "/" <> ".genex_passwords.gpg"

    "echo '#{data}' | gpg --quiet --encrypt --armor -r silbermm --no-tty --yes --batch --status-fd --with-colons -o #{
      filename
    }"
    |> String.to_char_list()
    |> :os.cmd()
  end
end
