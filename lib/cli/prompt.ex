defmodule Genex.CLI.Prompt do
  @moduledoc """
  Prompts in the CLI
  """

  alias IO.ANSI

  def prompt_for_specific_account(acc, credentials, password_handler) do
    IO.puts("There are multiple entries saved for #{acc}, which username are you searching for?")

    Enum.each(credentials, fn x ->
      IO.puts("#{x.username}")
    end)

    case IO.read(:stdio, :line) do
      :eof -> IO.puts("EOF encountered")
      {:error, reason} -> IO.puts("Error encountered")
      username -> password_handler.(acc, credentials, String.trim(username))
    end
  end

  def prompt_to_save(password, save_handler) do
    IO.write(ANSI.default_color() <> "Save this password (Y/n)?")

    case IO.read(:stdio, :line) do
      :eof -> IO.puts("EOF encountered")
      {:error, reason} -> IO.puts("Error encountered")
      answer -> save_handler.(password, answer)
    end
  end

  def prompt_for_next() do
    IO.puts("Generate a different password (y/N)?")
  end

  # TODO: need to hide user input
  def prompt_for_encryption_key_password(acc, password_handler) do
    IO.write("Enter private key password:")
    password = IO.read(:stdio, :line) |> String.trim()
    password_handler.(acc, password)
  end

  def prompt_for_account(password) do
    # TODO: error handling input
    IO.write("Enter an account that this password belongs to: ")
    account = IO.read(:stdio, :line) |> String.trim()
    IO.write("Enter a username for this account/password: ")
    username = IO.read(:stdio, :line) |> String.trim()
    Genex.Credentials.new(account, username, password)
  end
end
