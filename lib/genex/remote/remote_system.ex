defmodule Genex.Remote.RemoteSystem do
  @moduledoc """
  Defines remotes systems that the node knows about
  """
  use GenServer
  @tablename :remote_systems

  alias __MODULE__

  @type t() :: %__MODULE__{
          name: String.t() | nil,
          path: String.t() | nil,
          protocol: :file | nil,
          error: binary() | nil,
          strategy: module()
        }

  defstruct [:name, :path, :protocol, :error, :strategy]

  @doc """
  Create a new RemoteSystem from name and path
  """
  @spec new(String.t(), String.t()) :: t()
  def new(name, <<"file:" <> _>> = path) do
    %RemoteSystem{
      name: name,
      path: path,
      protocol: :file,
      strategy: Genex.Remote.LocalFileStrategy
    }
  end

  def new(name, <<"ssh:" <> _>> = path) do
    %RemoteSystem{
      name: name,
      path: path,
      protocol: :ssh,
      strategy: Genex.Remote.SSHStrategy
    }
  end

  def new(_, _), do: %RemoteSystem{error: "Unsupported Protocol"}

  @spec new(String.t(), :file | :ssh, String.t()) :: t()
  def new(name, path, protocol) do
    strategy = if protocol == :file do Genex.Remote.LocalFileStrategy else Genex.Remote.SSHStrategy
    %RemoteSystem{name: name, path: path, protocol: protocol, strategy: strategy}
  end

  def new({name, path, protocol}) do
    strategy = if protocol == :file do Genex.Remote.LocalFileStrategy else Genex.Remote.SSHStrategy
    %RemoteSystem{name: name, path: path, protocol: protocol, strategy: strategy}
  end

  def has_error?(%RemoteSystem{error: error}), do: !is_nil(error)
  def has_error?(_other), do: false

  @doc """
  Add a remote
  """
  @spec add(t()) :: :ok
  def add(%RemoteSystem{} = remote), do: GenServer.cast(__MODULE__, {:add, remote})

  @spec list() :: [t()]
  def list(), do: GenServer.call(__MODULE__, :list)

  @spec get(String.t()) :: t()
  def get(remote_name), do: GenServer.call(__MODULE__, {:get, remote_name})

  @spec delete(String.t()) :: boolean()
  def delete(remote_name), do: GenServer.call(__MODULE__, {:delete, remote_name})

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Process.flag(:trap_exit, true)
    filename = Application.get_env(:genex, :genex_home) <> "/remotes"
    {:ok, %{filename: filename}, {:continue, :init}}
  end

  @impl true
  def handle_call(:list, _from, state) do
    res = :ets.match_object(@tablename, {:"$1", :_, :_})
    remotes = Enum.map(res, &new/1)
    {:reply, remotes, state}
  end

  @impl true
  def handle_call({:get, remote_name}, _from, state) do
    res = :ets.match_object(@tablename, {remote_name, :_, :_})
    remotes = Enum.map(res, &new/1)

    case remotes do
      [] -> {:reply, %RemoteSystem{error: :noexist}, state}
      [h | _] -> {:reply, h, state}
    end
  end

  def handle_call({:delete, remote_name}, _from, %{filename: filename} = state) do
    res = :ets.delete(@tablename, remote_name)
    save_table(filename)
    {:reply, res, state}
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
