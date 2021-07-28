defmodule Genex.CLI.RemoteCommand do
  @moduledoc """
  #{IO.ANSI.green()}genex remote#{IO.ANSI.reset()}
  Add, list and delete trusted remotes

    --add,    --add <remote_name> Add a new remote
    --delete <remote_name>        Delete a remote
    --list,   -l                  List all known trusted remotes
    --help,   -h                  Prints this help message
  """

  use Prompt.Command
  alias __MODULE__

  @type t :: %RemoteCommand{
          help: boolean(),
          add: boolean(),
          delete: boolean(),
          list: boolean,
          remote_name: binary()
        }
  defstruct(help: false, add: false, delete: false, list: true, remote_name: "")

  @impl true
  def init(argv), do: parse(argv)

  @impl true
  def process(%RemoteCommand{help: true}), do: help()
  def process(%RemoteCommand{add: true}), do: add_remote()

  def process(%RemoteCommand{delete: true, remote_name: remote}) do
    case Genex.Remote.delete(remote) do
      :ok -> display("#{remote} deleted successfully", color: IO.ANSI.green())
      _ -> display("Error deleting #{remote}", error: true)
    end
  end

  def process(%RemoteCommand{list: true}) do
    case Genex.Remote.list_remotes() do
      [] ->
        display("No remotes configured")

      remotes ->
        remotes
        |> Enum.map(&[&1.name, &1.path])
        |> List.insert_at(0, ["Name", "Path"])
        |> table(header: true)
    end
  end

  @spec parse(list(String.t())) :: RemoteCommand.t()
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

  @spec _parse({list(), list(), list()}) :: RemoteCommand.t()
  defp _parse({[help: true], _, _}), do: %RemoteCommand{help: true}
  defp _parse({[add: true], _, _}), do: %RemoteCommand{add: true}
  defp _parse({[add: remote_name], _, _}), do: %RemoteCommand{add: true, remote_name: remote_name}
  defp _parse({[delete: true], _, _}), do: %RemoteCommand{delete: true}

  defp _parse({[delete: remote_name], _, _}),
    do: %RemoteCommand{delete: true, remote_name: remote_name}

  defp _parse({_, _, _}), do: %RemoteCommand{list: true}

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
