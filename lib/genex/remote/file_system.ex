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

  def copy_public_key(<<"ssh://" <> path>>, peer_id, raw_public_key) do
    [user, rest] = String.split(path, "@")
    [host, host_path] = String.split(rest, ":")

    host_path = Path.join(host_path, peer_id)
    remote_public_key_file = Path.join(host_path, "public_key.pem")

    case SSHEx.connect(ip: host, user: user) do
      {:ok, conn} ->
        with {:ok, _, _} <- SSHEx.run(conn, 'mkdir -p #{host_path}'),
             {:ok, _, _} <-
               SSHEx.run(conn, 'echo \"#{raw_public_key}\" > #{remote_public_key_file}') do
          :ok
        else
          err -> err
        end

      err ->
        err
    end
  end

  def copy_public_key(_, _), do: {:error, :invalid_protocol}

  def path_to_charlist(<<"file://" <> path>>), do: String.to_charlist(path)

  def path_to_charlist(<<"ssh://" <> path>>) do
    # path to tmpfile
    [tmp_filename, _] = String.split(path, ":")
    String.to_charlist(Path.join("/tmp", tmp_filename))
  end

  def path_to_charlist(path), do: String.to_charlist(path)

  def file_exists?(<<"file://" <> path>>), do: File.exists?(path)

  def file_exists?(<<"ssh://" <> path>>) do
    [user, rest] = String.split(path, "@")
    [host, host_path] = String.split(rest, ":")

    case SSHEx.connect(ip: host, user: user) do
      {:ok, conn} ->
        with {:ok, _, 0} <- SSHEx.run(conn, '[[ -f #{host_path} ]]') do
          true
        else
          {:ok, _, 1} -> false
          err -> false
        end

      err ->
        err
    end
  end

  def file_exists?(path), do: File.exists?(path)

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
