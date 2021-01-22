defmodule Genex.Remote do
  @moduledoc """
  Support for remote filesystem (file:// and ssh://) to sync changes to/from
  """

  @encryption Application.compile_env!(:genex, :encryption_module)

  @doc """
  Add a new remote for the local node and copy the nodes public key and metadata to the remote.
  """
  def add(name, path) do
    # add the remote to local node
    remote = Genex.Data.Remote.new(name, path)

    # get local node info
    local = Genex.Data.Manifest.get_local_info()

    if Genex.Data.Remote.has_error?(remote) do
      {:error, remote.error}
    else
      _ = Genex.Data.Remote.add(remote)
      # copy this nodes public key to the correct place on the remote storage
      _ = copy_public_key(remote, local)
      _ = Genex.Data.Remote.Supervisor.add_node(path, local)
    end
  end

  defp copy_public_key(remote, local_node) do
    # get local nodes public key
    raw_public_key = @encryption.local_public_key()
    path = Path.join(remote.path, local_node.id)
    remote_public_key_file = Path.join(path, "public_key.pem")

    mkdir = File.mkdir_p(path)

    if mkdir == :ok do
      File.write(remote_public_key_file, raw_public_key)
      # add node to remote manifest
    else
      mkdir
    end
  end

  @doc """
  List configured remotes.
  """
  def list_remotes(), do: Genex.Data.Remote.list()

  @doc """
  List the named remotes trusted peers
  """
  def list_remote_peers(remote) do
    configured_remote = Genex.Data.Remote.get(remote)

    if Genex.Data.Remote.has_error?(configured_remote) do
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
end
