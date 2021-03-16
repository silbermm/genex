defmodule Genex.Remote.Data.Passwords do
  @moduledoc "Save passwords for a remote node"
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(peer: peer) do
    Process.flag(:trap_exit, true)

    tablename =
      peer.id
      |> String.replace("-", "_")
      |> String.to_atom()

    path =
      if peer.remote.protocol == :file do
        <<"file:" <> tmp>> = peer.remote.path
        tmp
      else
        # TODO: ssh
        ""
      end

    {:ok, %{filename: path <> "/#{peer.id}/passwords", tablename: tablename}, {:continue, :init}}
  end

  def save_credentials(pid, account, username, created_at, encrypted_creds),
    do: GenServer.call(pid, {:save, account, username, created_at, encrypted_creds})

  def stop(pid), do: GenServer.stop(pid, :normal)

  @impl true
  def handle_call(:save, _from, %{tablename: tablename, filename: filename} = state) do
    res = save_table(tablename, filename)
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
  def handle_continue(
        :init,
        %{tablename: tablename, filename: filename} = state
      ) do
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
    IO.inspect("saving to #{filename}")
    res = :ets.tab2file(tablename, path)
    IO.inspect(res)
  end
end
