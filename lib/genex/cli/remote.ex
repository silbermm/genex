defmodule Genex.CLI.Remote do
  @moduledoc """
  #{IO.ANSI.green()}genex remote#{IO.ANSI.reset()}
  Add, list and delete trusted remotes

    --add,    --add <remote_name> Add a new remote
    --delete <remote_name>        Delete a remote
    --list,   -l                  List all known trusted remotes
    --help,   -h                  Prints this help message
  """

  alias __MODULE__
  import Prompt

  @type t :: %Remote{
          help: boolean(),
          add: boolean(),
          delete: boolean(),
          list: boolean,
          remote_name: binary()
        }
  defstruct(help: false, add: false, delete: false, list: true, remote_name: "")

  @doc "init the remote command"
  @spec init(list(String.t())) :: :ok | {:error, binary()}
  def init(argv) do
    argv
    |> parse()
    |> process()
  end

  @spec process(Remote.t()) :: :ok | {:error, any()}
  def process(%Remote{help: true}), do: display(@moduledoc)
  def process(%Remote{add: true}), do: add_remote()
  def process(%Remote{delete: true, remote_name: remote}), do: Genex.Remote.delete(remote)

  def process(%Remote{list: true}) do
    case Genex.Remote.list_remotes() do
      [] -> display("No remotes configured")
      remotes -> display(format_remotes(remotes))
    end
  end

  defp format_remotes(remotes) do
    Enum.map(remotes, fn r ->
      IO.ANSI.bright() <> "  * #{r.name}" <> IO.ANSI.normal() <> " " <> r.path
    end)
  end

  @spec parse(list(String.t())) :: Remote.t()
  defp parse(argv) do
    argv
    |> OptionParser.parse(
      switches: [
        help: :boolean,
        list: :boolean,
        add: :boolean,
        add: :string,
        delete: :string
      ],
      aliases: [h: :help, l: :list]
    )
    |> _parse()
  end

  @spec _parse({list(), list(), list()}) :: Remote.t()
  defp _parse({[help: true], _, _}), do: %Remote{help: true}
  defp _parse({[add: true], _, _}), do: %Remote{add: true}
  defp _parse({[add: remote_name], _, _}), do: %Remote{add: true, remote_name: remote_name}
  defp _parse({[delete: true], _, _}), do: %Remote{delete: true}
  defp _parse({[delete: remote_name], _, _}), do: %Remote{delete: true, remote_name: remote_name}
  defp _parse({_, _, _}), do: %Remote{list: true}

  defp add_remote() do
    res =
      select(
        "Choose a protocol",
        ["file://", "ssh://"]
      )

    case res do
      "file://" ->
        display(
          [
            "",
            "Enter the absolute path to the folder you want to use",
            "i.e /home/user/mnt/passwords\n"
          ],
          color: IO.ANSI.green()
        )

      "ssh://" ->
        display("Enter the path as user@host:/path", color: IO.ANSI.green())
    end

    path = text("Enter the path")

    display("Enter a name to use when referencing the remote\n",
      color: IO.ANSI.green()
    )

    name = text("Enter a name")

    case Genex.Remote.add(name, res <> path) do
      {:ok, remote} ->
        add_peers(remote)
        :ok

      _err ->
        display("Something went wrong.", color: IO.ANSI.red())
    end
  end

  defp add_peers(remote) do
    remote_peers = Genex.Remote.list_remote_peers(remote.name)

    for peer <- remote_peers do
      Genex.Remote.add_peer(peer, remote)
    end
  end
end
