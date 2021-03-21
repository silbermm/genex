defmodule Genex.Remote.FileSystem do
  @moduledoc """
  Deal with copying, moving and reading files from the filesystem (ssh or file)
  """

  @doc "Copy local public key to peers remote storage"
  @spec copy_public_key(binary(), binary(), binary()) :: :ok | {:error, binary()}
  def copy_public_key(<<"file:" <> path>>, peer_id, raw_public_key) do
    path = Path.join(path, peer_id)
    remote_public_key_file = Path.join(path, "public_key.pem")

    case File.mkdir_p(path) do
      :ok -> File.write(remote_public_key_file, raw_public_key)
      err -> err
    end
  end

  @doc "Delete the public key of a specific peer"
  @spec delete_public_key(binary(), binary()) :: :ok | {:error, binary()}
  def delete_public_key(<<"file:" <> path>>, peer_id) do
    path = Path.join(path, peer_id)

    case File.rm_rf(path) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc "Read the public key for a specific peer"
  @spec read_peer_public_key(binary(), binary()) :: binary()
  def read_peer_public_key(<<"file:" <> path>>, peer_id) do
    path = Path.join(path, peer_id)
    remote_public_key_file = Path.join(path, "public_key.pem")

    case File.read(remote_public_key_file) do
      {:ok, data} -> data
      _ -> ""
    end
  end
end
