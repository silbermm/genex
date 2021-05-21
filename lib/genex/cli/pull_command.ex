defmodule Genex.CLI.PullCommand do
  @moduledoc """

  #{IO.ANSI.green()}genex pull#{IO.ANSI.reset()}
  Pull passphrases from a remote to local store

    --remote, -r  The remote to pull from
    --help,   -h  Prints this help message

  """

  use Prompt.Command
  alias __MODULE__
  alias Genex.Remote

  @type t :: %PullCommand{
          help: boolean(),
          remote_name: binary()
        }
  defstruct(help: false, remote_name: "")

  @impl true
  def init(argv), do: parse(argv)

  @impl true
  def process(%PullCommand{help: true}), do: display(@moduledoc)

  def process(%PullCommand{}) do
    # pull remotes passwords into our db password
    remotes = Remote.list_remotes()

    res =
      select(
        "Choose a remote to pull from",
        Enum.map(remotes, fn r ->
          {IO.ANSI.bright() <> "  * #{r.name}" <> IO.ANSI.normal() <> " " <> r.path, r}
        end)
      )

    password = password("Private key password")
    Remote.pull(res, password)
  end

  @spec parse(list(String.t())) :: PullCommand.t()
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

  @spec _parse({list(), list(), list()}) :: PullCommand.t()
  defp _parse({[help: true], _, _}), do: %PullCommand{help: true}
  defp _parse({[remote: remote_name], _, _}), do: %PullCommand{remote_name: remote_name}
  defp _parse({_, _, _}), do: %PullCommand{}
end
