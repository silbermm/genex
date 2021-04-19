defmodule Genex.CLI.PeerCommand do
  @moduledoc """

  #{IO.ANSI.green()}genex peers#{IO.ANSI.reset()}
  List and manipulate peers for a remote

    --sync,       Syncs peers
    --help,   -h  Prints this help message

  """

  alias __MODULE__
  alias Genex.Remote
  import Prompt

  @type t :: %PeerCommand{help: boolean(), sync: boolean()}
  defstruct(help: false, sync: false)

  @spec init(list(String.t())) :: :ok | {:error, binary()}
  def init(argv) do
    argv |> parse() |> process()
  end

  @spec process(PeerCommand.t()) :: :ok | {:error, any()}
  def process(%PeerCommand{help: true}), do: display(@moduledoc)

  def process(%PeerCommand{sync: true}) do
    remotes = Remote.list_remotes()

    res =
      select(
        "Choose a remote to sync with",
        Enum.map(remotes, fn r ->
          {IO.ANSI.bright() <> "  * #{r.name}" <> IO.ANSI.normal() <> " " <> r.path, r}
        end)
      )

    case Remote.add(res.name, res.path) do
      {:ok, remote} ->
        add_peers(remote)

      _err ->
        display("Something went wrong.", color: IO.ANSI.red())
    end
  end

  def process(%PeerCommand{}) do
    peers = Remote.list_local_peers()
    peers = Enum.map(peers, &"#{&1.id} - #{&1.host} - #{&1.remote.name}")
    display(peers, color: IO.ANSI.green())
    :ok
  end

  defp add_peers(remote) do
    # add peers from remote just added
    remote_peers = Remote.list_remote_peers(remote.name)

    for peer <- remote_peers do
      Remote.add_peer(peer, remote)
    end
  end

  @spec parse(list(String.t())) :: PeerCommand.t()
  defp parse(argv) do
    argv
    |> OptionParser.parse(
      switches: [help: :boolean, sync: :boolean],
      aliases: [h: :help]
    )
    |> _parse()
  end

  @spec _parse({list(), list(), list()}) :: PeerCommand.t()
  defp _parse({[help: true], _, _}), do: %PeerCommand{help: true}
  defp _parse({[sync: true], _, _}), do: %PeerCommand{sync: true}
  defp _parse({_, _, _}), do: %PeerCommand{}
end
