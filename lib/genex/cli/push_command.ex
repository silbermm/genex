defmodule Genex.CLI.PushCommand do
  @moduledoc """

  #{IO.ANSI.green()}genex push#{IO.ANSI.reset()}
  Push local passphrases to a remote

    --remote, -r  The remote to push to
    --help,   -h  Prints this help message

  """

  alias __MODULE__
  alias Genex.Remote
  import Prompt

  @type t :: %PushCommand{
          help: boolean(),
          remote_name: binary()
        }
  defstruct(help: false, remote_name: "")

  @spec init(list(String.t())) :: :ok | {:error, binary()}
  def init(argv) do
    argv |> parse() |> process()
  end

  @spec process(PushCommand.t()) :: :ok | {:error, any()}
  def process(%PushCommand{help: true}), do: display(@moduledoc)

  def process(%PushCommand{}) do
    remotes = Remote.list_remotes()

    res =
      select(
        "Choose a remote to push to",
        Enum.map(remotes, fn r ->
          {IO.ANSI.bright() <> "  * #{r.name}" <> IO.ANSI.normal() <> " " <> r.path, r}
        end)
      )

    password = password("Private key password")
    Remote.push(res, password)
  end

  @spec parse(list(String.t())) :: PushCommand.t()
  defp parse(argv) do
    argv
    |> OptionParser.parse(
      switches: [
        help: :boolean,
        remote: :string
      ],
      aliases: [h: :help, r: :remote]
    )
    |> _parse()
  end

  @spec _parse({list(), list(), list()}) :: PushCommand.t()
  defp _parse({[help: true], _, _}), do: %PushCommand{help: true}
  defp _parse({[remote: remote_name], _, _}), do: %PushCommand{remote_name: remote_name}
  defp _parse({_, _, _}), do: %PushCommand{}
end
