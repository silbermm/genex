defmodule Genex.Data.Remote do
  @moduledoc """
  Defines remotes that the node knows about
  """
  use GenServer
  @tablename :remotes

  alias __MODULE__
  alias Genex.Environment

  @type t() :: %Remote{
          name: String.t() | nil,
          path: String.t() | nil,
          protocol: :file | nil,
          error: binary() | nil
        }

  defstruct [:name, :path, :protocol, :error]

  @doc """
  Create a new Remote from name and path
  """
  @spec new(String.t(), String.t()) :: t()
  def new(name, <<"file:" <> _>> = path) do
    %Remote{name: name, path: path, protocol: :file}
  end

  def new(_, _), do: %Remote{error: "Unsupported Protocol"}

  @spec new(String.t(), :file | :ssh, String.t()) :: t()
  def new(name, path, protocol) do
    %Remote{name: name, path: path, protocol: protocol}
  end

  def new({name, path, protocol}) do
    %Remote{name: name, path: path, protocol: protocol}
  end

  def has_error?(%Remote{error: error}), do: !is_nil(error)
  def has_error?(_other), do: false

  @doc """
  Add a remote
  """
  @spec add(t()) :: :ok
  def add(%Remote{} = remote), do: GenServer.cast(__MODULE__, {:add, remote})

  @spec list() :: [t()]
  def list(), do: GenServer.call(__MODULE__, :list)

  @spec get(String.t()) :: t()
  def get(remote_name), do: GenServer.call(__MODULE__, {:get, remote_name})

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Process.flag(:trap_exit, true)
    filename = Environment.load_variable("GENEX_REMOTES", :remotes_file)
    {:ok, %{filename: filename}, {:continue, :init}}
  end

  @impl true
  def handle_call(:list, _from, state) do
    res = :ets.match_object(@tablename, {:"$1", :_, :_})
    remotes = Enum.map(res, &new/1)
    {:reply, remotes, state}
  end

  @impl true
  def handle_call({:get, remote_name}, _from, %{filename: filename} = state) do
    res = :ets.match_object(@tablename, {remote_name, :_, :_})
    remotes = Enum.map(res, &new/1)

    case remotes do
      [] -> {:reply, %Remote{error: :noexist}, state}
      [h | _] -> {:reply, h, state}
    end
  end

  @impl true
  def handle_cast({:add, remote}, %{filename: filename} = state) do
    :ets.insert(@tablename, {remote.name, remote.path, remote.protocol})
    save_table(filename)
    {:noreply, state}
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
