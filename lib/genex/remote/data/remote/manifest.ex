defmodule Genex.Data.Remote.Manifest do
  @moduledoc """
  The remote manifest is the store that holds all the metadata about the node.
  Most notably:
    * the unique id and name for the local node
    * the other nodes that are trusted partners
  """
  use GenServer, restart: :temporary

  @tablename :remote_manifest

  alias __MODULE__
  alias Genex.Data.Manifest

  def start_link(path: path) do
    GenServer.start_link(__MODULE__, path, name: RemoteManifest)
  end

  @impl true
  def init("file:" <> path) do
    Process.flag(:trap_exit, true)
    {:ok, %{filename: Path.join(path, "manifest")}, {:continue, :init}}
  end

  @impl true
  def handle_call(:list, _from, state) do
    res = :ets.match_object(@tablename, {:"$1", :_, :_, false})
    all = Enum.map(res, &Manifest.new/1)
    {:stop, :normal, all, state}
  end

  @impl true
  def handle_call({:add, manifest}, _from, %{filename: filename} = state) do
    :ets.insert(@tablename, {manifest.id, manifest.host, manifest.os, false})
    save_table(filename)
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_call({:remove, manifest}, _from, %{filename: filename} = state) do
    res = :ets.delete(@tablename, manifest.id)
    save_table(filename)
    {:stop, :normal, res, state}
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
      save_table(filename)
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
end
