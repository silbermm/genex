defmodule Genex.Remote do
  @moduledoc """
  Support for configuring, pushing, pulling and syncing remotes (ssh or file) 
  """

  alias Genex.Data.Credentials
  alias Genex.Remote.RemoteSystem
  alias Genex.Manifest

  @encryption Application.compile_env!(:genex, :encryption_module)

  @doc """
  Add a new remote for the local node and copy
  the nodes public key and metadata to the remote
  """
  @spec add(String.t(), String.t()) :: {:ok, any()} | {:error, binary()}
  def add(name, path) do
    remote = RemoteSystem.new(name, path)

    local =
      Manifest.Store.get_local_info()
      |> Genex.Data.Manifest.add_remote(remote)

    with false <- RemoteSystem.has_error?(remote),
         :ok <- RemoteSystem.add(remote),
         :ok <- copy_public_key(remote, local),
         :ok <- Manifest.Supervisor.add_node(path, local) do
      {:ok, remote}
    else
      true -> {:error, remote.error}
      err -> err
    end
  end

  @doc "Delete a remote from the local node"
  @spec delete(binary()) :: :ok | :noexist | :error
  def delete(name) do
    with remote_system <- RemoteSystem.get(name),
         false <- RemoteSystem.has_error?(remote_system),
         local <- Manifest.Store.get_local_info(),
         :ok <- Genex.Remote.FileSystem.delete_public_key(remote_system.path, local.id) do
      RemoteSystem.delete(remote_system.name)
      Manifest.Supervisor.remove_node(remote_system.path, local)
    else
      {:error, reason, _} -> :error
      true -> :noexist
      _ -> :error
    end
  end

  @doc "List configured remotes"
  @spec list_remotes() :: list(RemoteSystem.t())
  defdelegate list_remotes(), to: RemoteSystem, as: :list

  @doc "List the named remotes trusted peers"
  @spec list_remote_peers(binary()) :: list(Genex.Data.Manifest.t()) | :error
  def list_remote_peers(remote_name) do
    configured_remote = Genex.Remote.RemoteSystem.get(remote_name)

    if Genex.Remote.RemoteSystem.has_error?(configured_remote) do
      :error
    else
      configured_remote.path
      |> Genex.Manifest.Supervisor.list_nodes()
      |> reject_local_node()
    end
  end

  @doc "List the local nodes trusted peers"
  @spec list_local_peers() :: list(Genex.Data.Manifest.t())
  def list_local_peers(), do: Manifest.Store.get_peers()

  @doc "Trust a peer from a configured remote"
  @spec add_peer(Genex.Data.Manifest.t(), RemoteSystem.t()) ::
          {:ok, binary()} | {:error, :nowrite}
  def add_peer(manifest, remote) do
    manifest = Genex.Data.Manifest.add_remote(manifest, remote)
    public_key = Genex.Remote.FileSystem.read_peer_public_key(remote.path, manifest.id)
    _add_peer(manifest, public_key)
  end

  @doc "Push local passwords to the remote for all peers to use"
  @spec push(Genex.Data.Manifest.t(), binary() | nil) :: [atom()]
  def push(remote, encryption_password) do
    peers = list_for_remote(remote)
    {:ok, all_creds} = Genex.Passwords.all(encryption_password)

    peers
    |> Enum.map(&build_push_tasks(&1, all_creds))
    |> Task.await_many()
  end

  @doc "Pull local passwords from the remote for local use"
  @spec pull(RemoteSystem.t(), binary() | nil) :: list(atom())
  def pull(remote, encryption_password) do
    local = Genex.Manifest.Store.get_local_info()
    {:ok, creds} = Genex.Passwords.all(encryption_password, remote: remote, id: local.id)
    IO.inspect(creds)
    # Enum.map(creds, &Genex.Passwords.save/1)
  end

  @spec build_push_tasks(Genex.Data.Manifest.t(), list(Credentials.t())) :: Task.t()
  defp build_push_tasks(peer, creds),
    do: Task.async(fn -> Genex.Passwords.save_for_peer(creds, peer, public_key_path(peer.id)) end)

  @spec build_pull_tasks(Genex.Data.Manifest.t(), binary() | nil) :: Task.t()
  defp build_pull_tasks(peer, password) do
    Task.async(fn ->
      password
      |> Genex.Passwords.all(peer)
      |> Enum.map(&Genex.Passwords.save/1)
    end)
  end

  @spec map_creds(binary() | :error) :: nil | Credentials.t()
  defp map_creds(:error), do: nil

  defp map_creds(creds) do
    creds
    |> Jason.decode!()
    |> Credentials.new()
  end

  @spec copy_public_key(RemoteSystem.t(), Genex.Data.Manifest.t()) :: :ok | {:error, atom()}
  defp copy_public_key(remote, local_node) do
    raw_public_key = @encryption.local_public_key()
    Genex.Remote.FileSystem.copy_public_key(remote.path, local_node.id, raw_public_key)
  end

  @spec reject_local_node(list(Genex.Data.Manifest.t())) :: list(Genex.Data.Manifest.t())
  defp reject_local_node(lst) do
    local = Genex.Manifest.Store.get_local_info()
    Enum.reject(lst, &(&1.id == local.id))
  end

  @spec _add_peer(Genex.Data.Manifest.t(), binary()) :: {:ok, binary()} | {:error, :nowrite}
  defp _add_peer(manifest, public_key) do
    folder = Path.join(home(), manifest.id)

    if !File.exists?(folder) do
      _ = File.mkdir(folder)
    end

    manifest.id
    |> public_key_path()
    |> File.write(public_key)
    |> case do
      :ok ->
        _ = Manifest.Store.add_peer(manifest)
        {:ok, manifest.id}

      _err ->
        {:error, :nowrite}
    end
  end

  @spec home() :: binary()
  defp home(), do: Application.get_env(:genex, :genex_home)

  @spec public_key_path(binary()) :: binary()
  defp public_key_path(peer_id) do
    home()
    |> Path.join(peer_id)
    |> Path.join("public_key.pem")
  end

  @spec list_for_remote(Genex.Data.Manifest.t()) :: list(Genex.Data.Manifest.t())
  defp list_for_remote(remote) do
    Manifest.Store.get_peers()
    |> Enum.reject(fn p -> p.remote.name != remote.name end)
  end
end
