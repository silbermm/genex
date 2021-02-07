defmodule Genex.Remote.FileSystem do
  @moduledoc """
  Deal with copying, moving and reading files from the filesystem (ssh or file)
  """

  def copy_public_key(<<"file:" <> path>>, node_id, raw_public_key) do
    path = Path.join(path, node_id)
    remote_public_key_file = Path.join(path, "public_key.pem")

    case File.mkdir_p(path) do
      :ok -> File.write(remote_public_key_file, raw_public_key)
      err -> err
    end
  end

  def delete_public_key(<<"file:" <> path>>, node_id) do
    path = Path.join(path, node_id)

    case File.rm_rf(path) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def read_remote_public_key(<<"file:" <> path>>, node_id) do
    path = Path.join(path, node_id)
    remote_public_key_file = Path.join(path, "public_key.pem")

    case File.read(remote_public_key_file) do
      {:ok, data} -> data
      _ -> ""
    end
  end
end
