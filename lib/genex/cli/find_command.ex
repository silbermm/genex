defmodule Genex.CLI.FindCommand do
  @moduledoc """
  #{IO.ANSI.green()}genex find <account_name>#{IO.ANSI.reset()}

  Show and manipulate saved passwords

    --delete, -d   Deletes the specified accounts passwords
    --help,   -h   Prints this help message

  """

  alias __MODULE__
  alias Genex.Passwords
  use Prompt.Command

  @type t :: %FindCommand{help: boolean(), account: String.t(), delete: boolean()}
  defstruct help: false, account: nil, delete: false

  @impl true
  def init(argv), do: parse(argv)

  @impl true
  @doc "process the command"
  def process(%FindCommand{help: true}), do: help()

  def process(%FindCommand{account: account, delete: delete}) do
    search_for(account, nil, delete: delete)
  end

  @spec parse(list(String.t())) :: FindCommand.t()
  defp parse(argv) do
    argv
    |> OptionParser.parse(
      strict: [help: :boolean, delete: :boolean],
      aliases: [h: :help, d: :delete]
    )
    |> _parse()
  end

  @spec _parse({list(), list(), list()}) :: FindCommand.t()
  defp _parse({_opts, [], _}), do: %FindCommand{help: true}
  defp _parse({[help: true], _, _}), do: %FindCommand{help: true}

  defp _parse({[delete: true], [account_name | _], _}),
    do: %FindCommand{delete: true, account: account_name}

  defp _parse({_, [account_name | _], _}), do: %FindCommand{account: account_name}

  defp search_for(account, password, opts) do
    case Passwords.find(account, password) do
      {:error, :password} ->
        password = password("Enter private key password")
        search_for(account, password, opts)

      res ->
        handle_found_account(account, res, opts)
    end
  end

  defp handle_found_account(account, res, opts) do
    delete? = Keyword.get(opts, :delete)
    count = Enum.count(res)

    cond do
      count == 0 ->
        display("Unable to find a password with that account name", error: true)

      delete? ->
        res
        |> List.first()
        |> handle_delete

      count == 1 ->
        creds = res |> List.first()

        creds.passphrase
        |> Diceware.with_colors()
        |> display(mask_line: true)

      count > 1 ->
        result =
          select(
            "Multiple entries saved for #{account}. Choose one",
            Enum.map(res, & &1.usernme)
          )

        handle_find_password_with_username(res, result)
    end
  end

  defp handle_delete(credentials) do
    answer =
      confirm("Are you sure you want to delete all passwords saved for this account?",
        default_answer: :no
      )

    case answer do
      :yes ->
        if Passwords.delete(credentials) do
          :ok
        else
          display("Unable to delete credentials", error: true)
          :ok
        end

      :no ->
        display("Deletion cancelled")
    end
  end

  defp handle_find_password_with_username(credentials, username) do
    credentials
    |> Enum.find(fn x -> x.username == username end)
    |> case do
      nil ->
        display("error ", error: true)

      res ->
        res.passphrase
        |> Diceware.with_colors()
        |> display(mask_line: true)
    end
  end
end
