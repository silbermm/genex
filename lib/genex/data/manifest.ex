defmodule Genex.Data.Manifest do
  @moduledoc """
  The manifest is the store that holds all the metadata about the node.
  Most notably: 
    * the unique id and name for the local node
    * the other nodes that are trusted partners
  """
  use GenServer

  @tablename :manifest

  alias __MODULE__

  @type t() :: %{
          id: String.t(),
          host: String.t(),
          os: atom(),
          is_local: bool(),
          remote: nil | %Genex.Remote.RemoteSystem.t()
        }
  defstruct [:id, :host, :os, :is_local]

  def new({id, host, os, is_local}), do: %Manifest{id: id, host: host, os: os, is_local: is_local}

  def new(%{id: id, host: host, os: os}),
    do: %Manifest{id: id, host: host, os: os, is_local: false}

  alias Genex.Environment

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Process.flag(:trap_exit, true)
    filename = Environment.load_variable("GENEX_MANIFEST", :manifest_file)
    {:ok, %{filename: filename}, {:continue, :init}}
  end

  @doc """
  Save the manifest file to the filesystem
  """
  def save_file(), do: GenServer.call(__MODULE__, :save)

  @spec get_local_info() :: Manifest.t()
  @doc "Get info about the local node"
  def get_local_info(), do: GenServer.call(__MODULE__, :get_local_info)

  @doc "Add a trusted peer to our manifest"
  def add_peer(peer_manifest), do: GenServer.call(__MODULE__, {:add_peer, peer_manifest})

  def get_peers(), do: GenServer.call(__MODULE__, :get_peers)

  @impl true
  def handle_call(:save, _from, %{filename: filename} = state) do
    res = save_table(filename)
    {:reply, res, state}
  end

  def handle_call(:get_local_info, _from, state) do
    res = :ets.match_object(@tablename, {:"$1", :_, :_, true})

    case res do
      [info | _] -> {:reply, new(info), state}
      _ -> {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:add_peer, peer_manifest}, _from, %{filename: filename} = state) do
    :ets.insert(@tablename, {peer_manifest.id, peer_manifest.host, peer_manifest.os, false})
    save_table(filename)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_peers, _from, state) do
    res = :ets.match_object(@tablename, {:"$1", :_, :_, false})
    peers = Enum.map(res, &new/1)
    {:reply, peers, state}
  end

  @impl true
  def handle_continue(:init, %{filename: filename} = state) do
    if File.exists?(filename) do
      path = String.to_charlist(filename)

      case :ets.file2tab(path) do
        {:ok, _} -> {:noreply, state}
        {:error, reason} -> {:stop, reason, state}
      end
    else
      _ = :ets.new(@tablename, [:set, :public, :named_table])
      initialize_manifest(filename)
      {:noreply, state}
    end
  rescue
    _err ->
      _ = :ets.new(@tablename, [:set, :public, :named_table])
      {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  @impl true
  def handle_info(_, %{filename: filename} = state) do
    save_table(filename)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{filename: filename}) do
    save_table(filename)
  end

  defp save_table(filename) do
    path = String.to_charlist(filename)
    _ = :ets.tab2file(@tablename, path)
  end

  defp initialize_manifest(filename) do
    {_, os} = :os.type()
    {:ok, host} = :inet.gethostname()
    is_local = true
    unique_id = UUID.uuid4()
    :ets.insert(@tablename, {unique_id, to_string(host), os, is_local})
    save_table(filename)
  end
end
