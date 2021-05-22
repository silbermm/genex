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

    context =
      SSHKit.context([host])
      |> SSHKit.path(Path.dirname(host_path))
      |> SSHKit.user(user)

    SSHKit.run(context, "mkdir -p #{host_path}")
    SSHKit.run(context, "echo \"#{raw_public_key}\" > #{remote_public_key_file}")
    :ok
  end

  def copy_public_key(_, _), do: {:error, :invalid_protocol}

  def path_to_charlist(<<"file://" <> path>>), do: String.to_charlist(path)

  def path_to_charlist(<<"ssh://" <> _path>>) do
    String.to_charlist("/tmp/manifest")
  end

  def path_to_charlist(path), do: String.to_charlist(path)

  def save_remote_table(<<"ssh://" <> path>>, tmp_file) do
    # copy tmp to path

    [user, rest] = String.split(path, "@")
    [host, host_path] = String.split(rest, ":")

    res =
      SSHKit.context([host])
      |> SSHKit.path(Path.dirname(host_path))
      |> SSHKit.user(user)
      |> SSHKit.upload(tmp_file)

    :ok
  end

  def save_remote_table(_, _), do: :ok

  def file_path(<<"ssh://" <> path>>) do
    [user, rest] = String.split(path, "@")
    [host, host_path] = String.split(rest, ":")

    tmp_file = "/tmp/manifest"

    context =
      SSHKit.context([host])
      |> SSHKit.path(Path.dirname(host_path))
      |> SSHKit.user(user)

    case SSHKit.run(context, "[[ -f #{host_path} ]]") do
      [{:ok, _, 0}] ->
        case SSHKit.SCP.download(context, host_path, as: tmp_file) do
          [:ok] -> {:ok, String.to_charlist(tmp_file)}
          _ -> {:error, :scp_error}
        end

      [{:ok, _, 1}] ->
        {:error, :enoexist}

      err ->
        err
    end
  end

  def file_path(<<"file://" <> path>>) do
    if File.exists?(path) do
      {:ok, String.to_charlist(path)}
    else
      {:error, :enoexists}
    end
  end

  def file_path(path) do
    if File.exists?(path) do
      {:ok, String.to_charlist(path)}
    else
      {:error, :enoexists}
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
