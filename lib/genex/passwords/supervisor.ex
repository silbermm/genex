defmodule Genex.Passwords.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def load_password_store(peer) do
    spec = {Genex.Passwords.Store, [peer: peer]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def save_credentials(peer_id, account, username, created_at, encrypted_creds) do
    name =
      peer_id
      |> String.replace("-", "_")
      |> String.to_atom()

    pid = GenServer.whereis(name)
    GenServer.call(pid, {:save, account, username, created_at, encrypted_creds})
  end

  def unload_password_store(peer) do
    name =
      peer.id
      |> String.replace("-", "_")
      |> String.to_atom()

    pid = GenServer.whereis(name)
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  catch
    e ->
      IO.inspect(e)
  end
end
