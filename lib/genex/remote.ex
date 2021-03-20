defmodule Genex.Remote do
  @moduledoc """
  Support for remote filesystem (file:// and ssh://) to sync changes to/from
  """

  alias Genex.Data.Credentials
  @encryption Application.compile_env!(:genex, :encryption_module)

  @doc """
  Add a new remote for the local node and copy the nodes public key and metadata to the remote.
  """
  @spec add(String.t(), String.t()) :: {:ok, any()} | {:error, binary()}
  def add(name, path) do
    # add the remote to local node
    remote = Genex.Remote.RemoteSystem.new(name, path)

    # get local node info
    local = Genex.Manifest.Store.get_local_info()
    local = %{local | remote: remote}

    if Genex.Remote.RemoteSystem.has_error?(remote) do
      {:error, remote.error}
    else
      with :ok <- Genex.Remote.RemoteSystem.add(remote),
           :ok <- copy_public_key(remote, local),
           :ok <- Genex.Manifest.Supervisor.add_node(path, local) do
        {:ok, remote}
      else
        err -> err
      end
    end
  end

  def delete(name) do
    with remote_system <- Genex.Remote.RemoteSystem.get(name),
         false <- Genex.Remote.RemoteSystem.has_error?(remote_system),
         local <- Genex.Manifest.Store.get_local_info() do
      _ = Genex.Remote.FileSystem.delete_public_key(remote_system.path, local.id)

      Genex.Remote.RemoteSystem.delete(remote_system.name)
      Genex.Manifest.Supervisor.remove_node(remote_system.path, local)
    else
      true ->
        :noexist

      _ ->
        nil
    end
  end

  defp copy_public_key(remote, local_node) do
    raw_public_key = @encryption.local_public_key()
    Genex.Remote.FileSystem.copy_public_key(remote.path, local_node.id, raw_public_key)
  end

  @doc """
  List configured remotes.
  """
  def list_remotes(), do: Genex.Remote.RemoteSystem.list()

  @doc """
  List the named remotes trusted peers
  """
  def list_remote_peers(remote) do
    configured_remote = Genex.Remote.RemoteSystem.get(remote)

    if Genex.Remote.RemoteSystem.has_error?(configured_remote) do
      :error
    else
      configured_remote.path
      |> Genex.Manifest.Supervisor.list_nodes()
      |> reject_local_node()
    end
  end

  defp reject_local_node(lst) do
    local = Genex.Manifest.Store.get_local_info()
    Enum.reject(lst, &(&1.id == local.id))
  end

  defdelegate list_local_peers(), to: Genex.Remote.LocalPeers, as: :list

  @doc """
  Add a peer from a remote to the local system
  """
  def add_peer(manifest, remote) do
    manifest = Genex.Data.Manifest.add_remote(manifest, remote)
    public_key = Genex.Remote.FileSystem.read_remote_public_key(remote.path, manifest.id)
    Genex.Remote.LocalPeers.add(manifest, public_key)
  end

  @doc """
  Push local passwords to the remote for all peers to use
  """
  def push(remote, encryption_password) do
    # encrypt passwords with each public key of peers for the specified remote

    # First, get peers for remote
    peers = Genex.Remote.LocalPeers.list_for_remote(remote)

    # get all encrypted creds
    {:ok, all_creds} = Genex.all(encryption_password)

    tasks =
      for peer <- peers do
        Task.async(fn -> Genex.Remote.LocalPeers.encrypt_for_peer(peer, all_creds) end)
      end

    tasks |> Task.await_many()
  end

  @doc """
  Pull local passwords from the remote for local use
  """
  def pull(remote, encryption_password) do
    peers = Genex.Remote.LocalPeers.list_for_remote(remote)

    tasks =
      for peer <- peers do
        Task.async(fn ->
          # get passwords from peer
          all = Genex.Remote.LocalPeers.load_from_peer(peer)
          # decrypt
          decrypted_creds =
            all
            |> Enum.map(fn {_account, _username, _date, creds} ->
              @encryption.decrypt(creds, encryption_password)
            end)
            |> Enum.map(&map_creds/1)
            |> Enum.reject(fn c -> c == nil end)

          # add to local db
          for cred <- decrypted_creds do
            Genex.save_credentials(cred)
          end
        end)
      end

    tasks |> Task.await_many()
  end

  defp map_creds(:error), do: nil

  defp map_creds(creds) do
    creds
    |> Jason.decode!()
    |> Credentials.new()
  end
end
