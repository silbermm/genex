defmodule Genex.Remote do
  @moduledoc """
  Support for remote filesystem (file:// and ssh://) to sync changes to/from
  """

  @encryption Application.compile_env!(:genex, :encryption_module)

  @doc """
  Add a new remote for the local node and copy the nodes public key and metadata to the remote.
  """
  @spec add(String.t(), String.t()) :: :ok | {:error, binary()}
  def add(name, path) do
    # add the remote to local node
    remote = Genex.Remote.RemoteSystem.new(name, path)

    # get local node info
    local = Genex.Data.Manifest.get_local_info()
    local = %{local | remote: remote}

    if Genex.Remote.RemoteSystem.has_error?(remote) do
      {:error, remote.error}
    else
      with :ok <- Genex.Remote.RemoteSystem.add(remote),
           :ok <- copy_public_key(remote, local),
           :ok <- Genex.Data.Remote.Supervisor.add_node(path, local) do
        :ok
      else
        err -> err
      end
    end
  end

  def delete(name) do
    with remote_system <- Genex.Remote.RemoteSystem.get(name),
         false <- Genex.Remote.RemoteSystem.has_error?(remote_system),
         local <- Genex.Data.Manifest.get_local_info() do
      # delete the public key from the remote if possible
      _ = Genex.Remote.FileSystem.delete_public_key(remote_system.path, local.id)

      # remove from the remote system file
      Genex.Remote.RemoteSystem.delete(remote_system.name)

      # remote from the remotes manifest
      Genex.Data.Remote.Supervisor.remove_node(remote_system.path, local)
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
      |> Genex.Data.Remote.Supervisor.list_nodes()
      |> reject_local_node()
    end
  end

  defp reject_local_node(lst) do
    local = Genex.Data.Manifest.get_local_info()
    Enum.reject(lst, &(&1.id == local.id))
  end

  defdelegate list_local_peers(), to: Genex.Remote.LocalPeers, as: :list

  def add_peer(id, name, os, remote) do
    # build manifest

    # add to local manifest file
  end
end
