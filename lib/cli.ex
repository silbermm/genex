defmodule Genex.CLI do
  @moduledoc """
  Password Manager that uses GPG to encrypt.

    --help          Prints help message
    --generate      Generate a password and save it
    --find account  Find a previously saved password based on a certain account
  """

  alias IO.ANSI

  def main(opts) do
    opts |> parse_args |> process
  end

  defp process(:help) do
    IO.puts @moduledoc
    System.halt(0)
  end

  defp process(:generate) do
    Genex.Password.generate()
    |> display
    |> prompt_to_save
  end

  defp process({:find, acc}) do
    res = Genex.Password.find_credentials(acc)
    count = Enum.count(res)
    cond do
      count == 0 -> IO.puts "Unable to find a password with that account name"
      count == 1 -> IO.puts "Found the account"
      count > 1 -> IO.puts "Multiple accounts with that name..."
    end
  end

  defp parse_args(opts) do
    cmd_opts =
      OptionParser.parse(opts,
        switches: [help: :boolean, generate: :boolean, find: :string],
        aliases: [h: :help, g: :generate, f: :find]
      )

    case cmd_opts do
      {[help: true], _, _} ->
        :help

      {[generate: true], _, _} ->
        :generate

      {[find: acc], _, _} ->
        {:find, acc}

      _ ->
        :help
    end
  end

  def display(password_list) do
    password_list
    |> with_colors
    |> IO.puts()

    Enum.join(password_list) |> String.trim()
  end

  def prompt_to_save(password) do
    IO.write(ANSI.default_color() <> "Save this password (Y/n)?")

    case IO.read(:stdio, :line) do
      :eof -> IO.puts("EOF encountered")
      {:error, reason} -> IO.puts("Error encountered")
      answer -> handle_save(password, answer)
    end
  end

  defp handle_save(password, answer) do
    case String.trim(answer) do
      "n" ->
        prompt_for_next()

      "N" ->
        prompt_for_next()

      "Y" ->
        prompt_for_account(password)

      "y" ->
        prompt_for_account(password)

      "" ->
        prompt_for_account(password)

      _ ->
        IO.puts("Sorry, I didn't understand your answer...")
        prompt_to_save(password)
    end
  end

  # TODO: implement
  defp prompt_for_next() do
    IO.puts("Generate a different password (y/N)?")
  end

  defp prompt_for_account(password) do
    # TODO: error handling input
    IO.write("Enter an account that this password belongs to: ")
    account = IO.read(:stdio, :line) |> String.trim()
    IO.write("Enter a username for this account/password: ")
    username = IO.read(:stdio, :line) |> String.trim()
    Genex.Password.save_credentials(account, username, password)
  end

  defp with_colors(wordlist) do
    [ANSI.cyan(), ANSI.magenta(), ANSI.yellow(), ANSI.blue(), ANSI.green(), ANSI.red()]
    |> Enum.zip(wordlist)
    |> Enum.map(fn {c, w} -> c <> w end)
    |> Enum.join()
  end
end
