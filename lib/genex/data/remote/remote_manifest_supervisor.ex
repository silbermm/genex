defmodule Genex.Data.Remote.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Add a node to the remote manifest
  """
  def add_node(remote_path, node_manifest) do
    spec = {Genex.Data.Remote.Manifest, [path: remote_path]}
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)
    GenServer.call(pid, {:add, node_manifest})
    GenServer.stop(pid)
  end

  def list_nodes(remote_path) do
    spec = {Genex.Data.Remote.Manifest, [path: remote_path]}
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)
    res = GenServer.call(RemoteManifest, :list)
    GenServer.stop(pid)
    res
  end
end
