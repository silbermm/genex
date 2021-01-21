defmodule Genex.Remote do
  @moduledoc """
  Support for remote filesystem (file:// and ssh://) to sync changes to/from
  """

  @encryption Application.compile_env!(:genex, :encryption_module)

  @doc """
  Add a new remote for the local node and copy the nodes public key to the remote.
  """
  def add(name, path) do
    # add the remote to local node
    remote = Genex.Data.Remote.new(name, path)

    if Genex.Data.Remote.has_error?(remote) do
      {:error, remote.error}
    else
      _ = Genex.Data.Remote.add(remote)
      # copy this nodes public key to the correct place on the remote storage
      copy_public_key(remote)

      # TODO: write data to remote manifest
    end
  end

  defp copy_public_key(remote) do
    # get local nodes public key
    raw_public_key = @encryption.local_public_key()
    local = Genex.Data.Manifest.get_local_info()
    path = Path.join(remote.path, local.id)
    remote_public_key_file = Path.join(path, "public_key.pem")

    mkdir = File.mkdir_p(path)

    if mkdir == :ok do
      File.write(remote_public_key_file, raw_public_key)
      # add node to remote manifest
    else
      mkdir
    end
  end
end
