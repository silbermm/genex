defmodule Genex.Manifest.Store do
  @moduledoc """
  The manifest store holds all the metadata about the node.
  Most notably: 
    * the unique id and name for the local node
    * the other nodes that are trusted peers

  If called with a path argument, we assume this is a store for remote manifests

  A remote manifest holds information about all of the nodes that are trusted peers
  of that particular remote
  """
  use GenServer, restart: :temporary
  import Genex.Data.Manifest
  alias Genex.Data.Manifest

  def start_link(remote: remote) do
    GenServer.start_link(__MODULE__, {:remote, remote}, name: :remote_manifest)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: :manifest)
  end

  @impl true
  def init(:ok) do
    Process.flag(:trap_exit, true)
    filename = Application.get_env(:genex, :genex_home) <> "/manifest"
    tablename = :manifest

    {:ok,
     %{
       filename: filename,
       tablename: tablename,
       remote: false,
       strategy: Genex.Remote.LocalFileStrategy
     }, {:continue, :init}}
  end

  def init({:remote, remote}) do
    Process.flag(:trap_exit, true)
    tablename = :remote_manifest

    {:ok,
     %{
       strategy: remote.strategy,
       filename: Path.join(remote.path, "manifest"),
       tablename: tablename,
       remote: true
     }, {:continue, :init}}
  end

  @doc """
  Save the manifest file to the filesystem
  """
  def save_file(), do: GenServer.call(__MODULE__, :save)

  @spec get_local_info() :: Manifest.t()
  @doc "Get info about the local node"
  def get_local_info(), do: GenServer.call(:manifest, :get_local_info)

  @doc "Add a trusted peer to our manifest"
  def add_peer(peer_manifest), do: GenServer.call(:manifest, {:add_peer, peer_manifest})

  def get_peers(), do: GenServer.call(:manifest, :get_peers)

  @impl true
  def handle_call(
        :save,
        _from,
        %{filename: filename, tablename: tablename, proto: _proto, strategy: strategy} = state
      ) do
    res = save_table(tablename, filename, strategy)
    {:reply, res, state}
  end

  def handle_call(:get_local_info, _from, %{tablename: tablename} = state) do
    res = :ets.match_object(tablename, {:"$1", :_, :_, true, :_})

    case res do
      [info | _] -> {:reply, new(info), state}
      _ -> {:reply, nil, state}
    end
  end

  @impl true
  def handle_call(
        {:add_peer, peer_manifest},
        _from,
        %{filename: filename, tablename: tablename, strategy: strategy} = state
      ) do
    :ets.insert(
      tablename,
      {peer_manifest.id, peer_manifest.host, peer_manifest.os, false, peer_manifest.remote}
    )

    save_table(tablename, filename, strategy)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(
        {:add_remote_manifest, manifest},
        _from,
        %{filename: filename, tablename: tablename, remote: true, strategy: strategy} = state
      ) do
    :ets.insert(tablename, {manifest.id, manifest.host, manifest.os, false})
    save_table(tablename, filename, strategy)
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_call(
        {:remove_remote_manifest, manifest},
        _from,
        %{tablename: tablename, filename: filename, remote: true, strategy: strategy} = state
      ) do
    :ets.delete(tablename, manifest.id)
    save_table(tablename, filename, strategy)
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_call(:get_peers, _from, %{tablename: tablename} = state) do
    res = :ets.match_object(tablename, {:"$1", :_, :_, false, :_})
    peers = Enum.map(res, &new/1)
    {:reply, peers, state}
  end

  @doc "List all non locals"
  @impl true
  def handle_call(:list_remote_manifests, _from, %{tablename: tablename, remote: true} = state) do
    all =
      tablename
      |> :ets.match_object({:"$1", :_, :_, false})
      |> Enum.map(&new/1)

    {:stop, :normal, all, state}
  end

  @impl true
  def handle_continue(
        :init,
        %{tablename: tablename, filename: filename, strategy: strategy} = state
      ) do
    case strategy.filepath(filename) do
      {:ok, path} ->
        case :ets.file2tab(path) do
          {:ok, _} -> {:noreply, state}
          {:error, reason} -> {:stop, reason, state}
        end

      {:error, _err} ->
        _ = :ets.new(tablename, [:set, :protected, :named_table])

        if !state.remote do
          initialize_manifest(tablename, filename, strategy)
        end

        {:noreply, state}
    end
  rescue
    err ->
      _ = :ets.new(tablename, [:set, :protected, :named_table])
      {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  @impl true
  def handle_info(_, %{tablename: tablename, filename: filename, strategy: strategy} = state) do
    save_table(tablename, filename, strategy)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{tablename: tablename, filename: filename, strategy: strategy}) do
    save_table(tablename, filename, strategy)
  end

  defp save_table(tablename, filename, strategy) do
    path = strategy.charlist_from_path(filename)

    case :ets.tab2file(tablename, path) do
      :ok ->
        # save back to remote filesystem~
        strategy.post_save(filename, path)

      _ ->
        :error
    end
  end

  defp initialize_manifest(tablename, filename, strategy) do
    {_, os} = :os.type()
    {:ok, host} = :inet.gethostname()
    is_local = true
    unique_id = UUID.uuid4()
    res = :ets.insert(tablename, {unique_id, to_string(host), os, is_local, nil})
    save_table(tablename, filename, strategy)
  end
end
