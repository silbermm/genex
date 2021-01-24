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
end