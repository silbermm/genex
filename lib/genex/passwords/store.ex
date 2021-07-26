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

    {:ok, %{tablename: tablename, table: nil, filename: filename, remote: true},
     {:continue, :init}}
  end

  def save_file(), do: GenServer.call(:passwords, :save)

  def save_credentials(account, username, created_at, encrypted_creds),
    do: GenServer.call(:passwords, {:save, account, username, created_at, encrypted_creds})

  def save_credentials(account, encrypted_creds),
    do:
      GenServer.call(
        :passwords,
        {:save, account.account, account.username, account.created_at, encrypted_creds}
      )

  def find_account(account), do: GenServer.call(:passwords, {:find, account})

  def delete(account), do: GenServer.call(:passwords, {:delete, account})

  def list_accounts(), do: GenServer.call(:passwords, :list)

  def all(), do: GenServer.call(:passwords, :all)

  @impl true
  def handle_call(:save, _from, %{table: table, filename: filename} = state) do
    res = save_table(table, filename)
    {:reply, res, state}
  end

  def handle_call({:find, account}, _from, %{table: table} = state) do
    res = :ets.match_object(table, {account, :_, :_, :_})
    {:reply, res, state}
  end

  def handle_call({:delete, account}, _from, %{table: table} = state) do
    # res = :ets.match_object(table, {account, :_, :_, :_})
    res = :ets.delete(table, account)
    {:reply, res, state}
  end

  def handle_call(:list, _from, %{table: table} = state) do
    res = :ets.match_object(table, {:"$1", :_, :_, :_})
    {:reply, res, state}
  end

  def handle_call(:all, _from, %{table: table} = state) do
    res = :ets.match_object(table, {:"$1", :"$2", :"$3", :"$4"})
    {:reply, res, state}
  end

  def handle_call(:debug, _from, %{table: table} = state) do
    res = :ets.tab2list(table)
    {:reply, res, state}
  end

  @impl true
  def handle_call(
        {:save, account, username, created_at, creds},
        _from,
        %{table: table, filename: filename} = state
      ) do
    :ets.insert(table, {account, username, created_at, creds})
    res = save_table(table, filename)
    {:reply, res, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  @impl true
  def handle_info(_, %{table: table, filename: filename} = state) do
    save_table(table, filename)
    {:noreply, state}
  end

  @impl true
  def handle_continue(:init, %{tablename: tablename, filename: filename} = state) do
    if File.exists?(filename) do
      path = String.to_charlist(filename)

      case :ets.file2tab(path) do
        {:ok, table} -> {:noreply, %{state | table: table}}
        {:error, reason} -> {:stop, reason, state}
      end
    else
      table = :ets.new(tablename, [:bag, :protected])
      {:noreply, %{state | table: table}}
    end
  rescue
    _err ->
      table = :ets.new(tablename, [:bag, :protected])
      {:noreply, %{state | table: table}}
  end

  @impl true
  def terminate(_reason, %{table: table, filename: filename}) do
    save_table(table, filename)
  end

  def save_table(table, filename) do
    path = String.to_charlist(filename)
    _ = :ets.tab2file(table, path)
  end

  def get_tablename(peer: peer) do
    peer.id
    |> String.replace("-", "_")
    |> String.to_atom()
  end

  def get_tablename(remote: remote, peer_id: id) do
    (id <> remote.name)
    |> String.replace("-", "_")
    |> String.replace(" ", "")
    |> String.to_atom()
  end

  def get_tablename(_), do: :passwords

  defp get_filename(peer: peer) do
    if peer.remote.protocol == :file do
      <<"file:" <> tmp>> = peer.remote.path
      tmp <> "/#{peer.id}/passwords"
    else
      ""
    end
  end

  defp get_filename(remote: remote, peer_id: id) do
    if remote.protocol == :file do
      <<"file:" <> tmp>> = remote.path
      tmp <> "/#{id}/passwords"
    else
      ""
    end
  end

  defp get_filename(_), do: Application.get_env(:genex, :genex_home) <> "/passwords"
end
