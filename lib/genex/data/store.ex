defmodule Genex.Data.Passwords do
  @moduledoc "Save and retrieve credentials"
  use GenServer

  alias Genex.Environment
  @tablename :passwords

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Process.flag(:trap_exit, true)
    filename = Environment.load_variable("GENEX_PASSWORDS", :passwords_file)
    {:ok, %{filename: filename}, {:continue, :init}}
  end

  def save_file(), do: GenServer.call(__MODULE__, :save)

  def save_credentials(account, username, created_at, encrypted_creds),
    do: GenServer.call(__MODULE__, {:save, account, username, created_at, encrypted_creds})

  def find_account(account), do: GenServer.call(__MODULE__, {:find, account})

  def list_accounts(), do: GenServer.call(__MODULE__, :list)

  def all(), do: GenServer.call(__MODULE__, :all)

  @impl true
  def handle_call(:save, _from, %{filename: filename} = state) do
    res = save_table(filename)
    {:reply, res, state}
  end

  def handle_call({:find, account}, _from, state) do
    res = :ets.match_object(@tablename, {account, :_, :_, :_})
    {:reply, res, state}
  end

  def handle_call(:list, _from, state) do
    res = :ets.match_object(@tablename, {:"$1", :_, :_, :_})
    {:reply, res, state}
  end

  def handle_call(:all, _from, state) do
    res = :ets.match_object(@tablename, {:"$1", :"$2", :"$3", :"$4"})
    {:reply, res, state}
  end

  @impl true
  def handle_call(
        {:save, account, username, created_at, creds},
        _from,
        %{filename: filename} = state
      ) do
    :ets.insert(@tablename, {account, username, created_at, creds})
    res = save_table(filename)
    {:reply, res, state}
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
  def handle_continue(:init, %{filename: filename} = state) do
    if File.exists?(filename) do
      path = String.to_charlist(filename)

      case :ets.file2tab(path) do
        {:ok, _} -> {:noreply, state}
        {:error, reason} -> {:stop, reason, state}
      end
    else
      _ = :ets.new(@tablename, [:bag, :public, :named_table])
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
end
