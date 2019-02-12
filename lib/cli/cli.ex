defmodule Genex.CLI do
  @moduledoc """
  Password Manager that uses GPG to encrypt.

    --help          Prints help message
    --generate      Generate a password and save it
    --find account  Find a previously saved password based on a certain account
  """

  alias IO.ANSI
  alias Genex.CLI.Prompt

  def main(opts) do
    opts
    |> parse_args
    |> process
  end

  defp process(:help) do
    IO.puts(@moduledoc)
    System.halt(0)
  end

  defp process(:generate) do
    Genex.generate_password()
    |> display
    |> Prompt.prompt_to_save(&handle_save/2)
  end

  defp process({:find, acc}) do
    search_for(acc, nil)
  end

  defp search_for(acc, password) do
    case Genex.find_credentials(acc, password) do
      {:error, password} -> Prompt.prompt_for_encryption_key_password(acc, &search_for/2)
      :error -> IO.puts("error encountered when searching for account")
      res ->
        count = Enum.count(res)

        cond do
          count == 0 ->
            IO.puts("Unable to find a password with that account name")

          count == 1 ->
            IO.puts("#{List.first(res).password}")

          count > 1 ->
            Prompt.prompt_for_specific_account(acc, res, &handle_find_password_with_username/3)
        end
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

  defp handle_find_password_with_username(acc, credentials, username) do
    credentials
    |> Enum.find(fn x -> x.username == username end)
    |> case do
      nil ->
        IO.puts("Input didn't match any kmown username, try again")

        Prompt.prompt_for_specific_account(
          acc,
          credentials,
          &handle_find_password_with_username/3
        )

      res ->
        IO.puts("Password = #{res.password}")
    end
  end

  defp handle_save(password, answer) do
    answer
    |> String.trim()
    |> String.downcase()
    |> case do
      "n" ->
        Prompt.prompt_for_next()

      "y" ->
        password
        |> Prompt.prompt_for_account()
        |> save_creds

      "" ->
        password
        |> Prompt.prompt_for_account()
        |> save_creds

      _ ->
        IO.puts("Sorry, I didn't understand your answer...")
        Prompt.prompt_to_save(password)
    end
  end

  defp save_creds(credentials) do
    case Genex.save_credentials(credentials) do
      :ok ->
        IO.puts("Account saved")
        System.halt(0)

      {:error, :not_unique} ->
        IO.puts("That account and username combination already exists in the system")
        System.halt(1)

      :error ->
        IO.puts("Something went wrong trying to save your password, please try again")
        System.halt(2)
    end
  end

  defp with_colors(wordlist) do
    [ANSI.cyan(), ANSI.magenta(), ANSI.yellow(), ANSI.blue(), ANSI.green(), ANSI.red()]
    |> Enum.zip(wordlist)
    |> Enum.map(fn {c, w} -> c <> w end)
    |> Enum.join()
  end
end
