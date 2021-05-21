defmodule Genex.CLI.ShowCommand do
  @moduledoc """
  #{IO.ANSI.green()}genex ShowCommand <account_name>#{IO.ANSI.reset()}

  Shows saved password for an account

    --help, -h   Prints this help message
  """

  alias __MODULE__
  alias Genex.Passwords
  use Prompt.Command

  @type t :: %ShowCommand{help: boolean(), account: String.t()}
  defstruct help: false, account: nil

  @doc "init the Show command"
  @impl true
  def init(argv), do: parse(argv)

  @impl true
  @doc "process the command"
  def process(%ShowCommand{help: true}), do: display(@moduledoc)
  def process(%ShowCommand{account: account}), do: search_for(account, nil)

  @spec parse(list(String.t())) :: ShowCommand.t()
  defp parse(argv) do
    argv
    |> OptionParser.parse(strict: [help: :boolean], aliases: [h: :help])
    |> _parse()
  end

  @spec _parse({list(), list(), list()}) :: ShowCommand.t()
  defp _parse({_opts, [], _}), do: %ShowCommand{help: true}
  defp _parse({[help: true], _, _}), do: %ShowCommand{help: true}
  defp _parse({_, [account_name | _], _}), do: %ShowCommand{help: false, account: account_name}

  defp search_for(acc, password) do
    case Passwords.find(acc, password) do
      {:error, :password} ->
        password = password("Enter private key password")
        search_for(acc, password)

      res ->
        count = Enum.count(res)

        cond do
          count == 0 ->
            display("Unable to find a password with that account name", error: true)

          count == 1 ->
            creds = res |> List.first()

            creds.passphrase
            |> Diceware.with_colors()
            |> display(mask_line: true)

          count > 1 ->
            result =
              select(
                "Multiple entries saved for #{acc}. Choose one",
                Enum.map(res, & &1.username)
              )

            handle_find_password_with_username(res, result)
        end
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
