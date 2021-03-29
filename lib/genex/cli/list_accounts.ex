defmodule Genex.CLI.ListAccounts do
  @moduledoc """
  genex list - lists the accounts that are known to the system

    --help, -h   Prints this help message
  """

  alias __MODULE__
  alias Genex.Passwords
  import Prompt

  @type t :: %ListAccounts{
          help: boolean()
        }
  defstruct help: false

  @doc "init the generate command"
  @spec(init(list(String.t())) :: :ok, {:error, binary()})
  def init(argv) do
    argv
    |> parse()
    |> process()
  end

  @doc "parse the command line arguments for the list command"
  @spec parse(list(String.t())) :: ListAccounts.t()
  def parse(argv) do
    argv
    |> OptionParser.parse(strict: [help: :boolean], aliases: [h: :help])
    |> _parse()
  end

  @spec _parse({list(), list(), list()}) :: Generate.t()
  defp _parse({opts, _, _}) do
    help = Keyword.get(opts, :help, false)
    %ListAccounts{help: help}
  end

  @spec process(Generate.t()) :: :ok
  defp process(%ListAccounts{help: true}), do: display(@moduledoc)

  defp process(%ListAccounts{} = _) do
    Passwords.list_accounts()
    |> display(color: IO.ANSI.green())

    :ok
  end
end
