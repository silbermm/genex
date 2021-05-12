defmodule Genex.CLI.ListAccountsCommand do
  @moduledoc """
  #{IO.ANSI.green()}genex list#{IO.ANSI.reset()}
  Lists the accounts that are known to the system

    --help, -h   Prints this help message
  """

  alias __MODULE__
  alias Genex.Passwords
  use Prompt.Command

  @type t :: %ListAccountsCommand{help: boolean()}
  defstruct help: false

  @doc "init the list accounts command"
  def init(argv) do
    argv
    |> parse()
  end

  @spec parse(list(String.t())) :: ListAccountsCommand.t()
  defp parse(argv) do
    argv
    |> OptionParser.parse(strict: [help: :boolean], aliases: [h: :help])
    |> _parse()
  end

  @spec _parse({list(), list(), list()}) :: ListAccountsCommand.t()
  defp _parse({opts, _, _}) do
    help = Keyword.get(opts, :help, false)
    %ListAccountsCommand{help: help}
  end

  def process(%ListAccountsCommand{help: true}), do: display(@moduledoc)

  def process(%ListAccountsCommand{} = _) do
    Passwords.list_accounts()
    |> display(color: IO.ANSI.green())

    :ok
  end
end
