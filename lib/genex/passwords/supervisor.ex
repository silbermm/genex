defmodule Genex.Passwords.Supervisor do
  @moduledoc """
  A Dynamic Supervisor for different password stores on a remote store
  """
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def load_password_store(%Genex.Data.Manifest{} = peer) do
    spec = {Genex.Passwords.Store, [peer: peer]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def load_password_store(%Genex.Remote.RemoteSystem{} = remote, peer_id) do
    spec = {Genex.Passwords.Store, [remote: remote, peer_id: peer_id]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def save_credentials(peer_id, credentials, encrypted_creds) do
    [peer: %{id: peer_id}]
    |> Genex.Passwords.Store.get_tablename()
    |> GenServer.whereis()
    |> GenServer.call(
      {:save, credentials.account, credentials.username, credentials.created_at, encrypted_creds}
    )
  end

  def all_credentials(peer_id) do
    name =
      peer_id
      |> String.replace("-", "_")
      |> String.to_atom()

    pid = GenServer.whereis(name)
    GenServer.call(pid, :debug)
  end

  def all_credentials(remote, peer_id) do
    [remote: remote, peer_id: peer_id]
    |> Genex.Passwords.Store.get_tablename()
    |> GenServer.whereis()
    |> GenServer.call(:all)
  end

  def unload_password_store(peer) do
    name =
      peer.id
      |> String.replace("-", "_")
      |> String.to_atom()

    pid = GenServer.whereis(name)
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  rescue
    _e -> :error
  end

  def unload_password_store(remote, peer_id) do
    pid =
      [remote: remote, peer_id: peer_id]
      |> Genex.Passwords.Store.get_tablename()
      |> GenServer.whereis()

    DynamicSupervisor.terminate_child(__MODULE__, pid)
  rescue
    _e -> :error
  end
end
