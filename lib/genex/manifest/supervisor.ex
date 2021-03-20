defmodule Genex.Manifest.Supervisor do
  @moduledoc """
  A dynamic supervisor for Manifests typically used for remote manifests
  """
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_node(remote_path, node_manifest) do
    spec = {Genex.Manifest.Store, [path: remote_path]}
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)
    GenServer.call(pid, {:add_remote_manifest, node_manifest})
  end

  def remove_node(remote_path, node_manifest) do
    spec = {Genex.Manifest.Store, [path: remote_path]}
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)
    GenServer.call(pid, {:remove_remote_manifest, node_manifest})
  end

  def list_nodes(remote_path) do
    spec = {Genex.Manifest.Store, [path: remote_path]}
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)
    GenServer.call(pid, :list_remote_manifests)
  end
end
