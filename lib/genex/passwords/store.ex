defmodule Genex.Passwords.Store do
  @moduledoc "Save and retrieve credentials"
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: get_tablename(args))
  end

  @impl true
  def init(args) do
    Process.flag(:trap_exit, true)
    # get filename 
    filename = get_filename(args)
    tablename = get_tablename(args)
    {:ok, %{tablename: tablename, filename: filename}, {:continue, :init}}
  end

  def save_file(), do: GenServer.call(:passwords, :save)

  def save_credentials(account, username, created_at, encrypted_creds),
    do: GenServer.call(:passwords, {:save, account, username, created_at, encrypted_creds})

  def find_account(account), do: GenServer.call(:passwords, {:find, account})

  def list_accounts(), do: GenServer.call(:passwords, :list)

  def all(), do: GenServer.call(:passwords, :all)

  @impl true
  def handle_call(:save, _from, %{tablename: tablename, filename: filename} = state) do
    res = save_table(tablename, filename)
    {:reply, res, state}
  end

  def handle_call({:find, account}, _from, %{tablename: tablename} = state) do
    res = :ets.match_object(tablename, {account, :_, :_, :_})
    {:reply, res, state}
  end

  def handle_call(:list, _from, %{tablename: tablename} = state) do
    res = :ets.match_object(tablename, {:"$1", :_, :_, :_})
    {:reply, res, state}
  end

  def handle_call(:all, _from, %{tablename: tablename} = state) do
    res = :ets.match_object(tablename, {:"$1", :"$2", :"$3", :"$4"})
    {:reply, res, state}
  end

  @impl true
  def handle_call(
        {:save, account, username, created_at, creds},
        _from,
        %{tablename: tablename, filename: filename} = state
      ) do
    :ets.insert(tablename, {account, username, created_at, creds})
    res = save_table(tablename, filename)
    {:reply, res, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  @impl true
  def handle_info(_, %{tablename: tablename, filename: filename} = state) do
    save_table(tablename, filename)
    {:noreply, state}
  end

  @impl true
  def handle_continue(:init, %{tablename: tablename, filename: filename} = state) do
    if File.exists?(filename) do
      path = String.to_charlist(filename)

      case :ets.file2tab(path) do
        {:ok, _} -> {:noreply, state}
        {:error, reason} -> {:stop, reason, state}
      end
    else
      _ = :ets.new(tablename, [:bag, :protected, :named_table])
      {:noreply, state}
    end
  rescue
    _err ->
      _ = :ets.new(tablename, [:bag, :protected, :named_table])
      {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{tablename: tablename, filename: filename}) do
    save_table(tablename, filename)
  end

  defp save_table(tablename, filename) do
    path = String.to_charlist(filename)
    _ = :ets.tab2file(tablename, path)
  end

  defp get_tablename(peer: peer) do
    peer.id
    |> String.replace("-", "_")
    |> String.to_atom()
  end

  defp get_tablename(_), do: :passwords

  defp get_filename(peer: peer) do
    if peer.remote.protocol == :file do
      <<"file:" <> tmp>> = peer.remote.path
      tmp <> "/#{peer.id}/passwords"
    else
      ""
    end
  end

  defp get_filename(_), do: Application.get_env(:genex, :genex_home) <> "/passwords"
end
