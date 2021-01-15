defmodule Genex.Data.Manifest do
  @moduledoc """
  The manifest is the store that holds all the metadata about the node.
  Most notably: 
    * the unique id and name for the local node
    * the other nodes that are trusted partners
  """
  use GenServer

  @tablename :manifest

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

  def get_local_id(), do: GenServer.call(__MODULE__, :get_local_id)

  @impl true
  def handle_call(:save, _from, %{filename: filename} = state) do
    res = save_table(filename)
    {:reply, res, state}
  end

  def handle_call(:get_local_id, _from, state) do
    res = :ets.match_object(@tablename, {:"$1", :_, true})
    IO.inspect res
    {:reply, res, state}
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
      _ = :ets.new(@tablename, [:bag, :public, :named_table])
      initialize_manifest()
      {:noreply, state}
    end
  rescue
    _err ->
      _ = :ets.new(@tablename, [:bag, :public, :named_table])
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

  defp initialize_manifest() do
    IO.inspect "INITIALIZE"
    {_, os} = :os.type()
    {:ok, host} = :inet.gethostname()
    is_local = true
    unique_id = UUID.uuid4()
    _ = :ets.insert(@tablename, {unique_id, host, os, is_local})
  end
end
