defmodule Genex.Remote.LocalFileStrategy do
  @moduledoc """
  A remote strategy that makes use of the local filesystem, think
  USB, microSD card, mounted network drives.
  """

  @behaviour Genex.Remote.Strategy

  @impl true
  @doc "Copy local public key to peers remote storage"
  def copy_public_key(<<"file:" <> path>>, peer_id, public_key) do
    path = Path.join(path, peer_id)
    remote_public_key_file = Path.join(path, "public_key.pem")

    case File.mkdir_p(path) do
      :ok -> File.write(remote_public_key_file, public_key)
      err -> err
    end
  end

  @impl true
  @doc "Delete the public key of a specific peer"
  def delete_public_key(<<"file:" <> path>>, peer_id) do
    path = Path.join(path, peer_id)

    case File.rm_rf(path) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @impl true
  @doc "Read the public key for a specific peer"
  def read_peer_public_key(<<"file:" <> path>>, peer_id) do
    path = Path.join(path, peer_id)
    remote_public_key_file = Path.join(path, "public_key.pem")

    case File.read(remote_public_key_file) do
      {:ok, data} -> data
      _ -> ""
    end
  end

  @impl true
  @doc "build a charlist of the path to a locally accessible remote manifest"
  def charlist_from_path(<<"file://" <> path>>), do: String.to_charlist(path)

  @impl true
  @doc "If the remote manifest exists, return a charlist of the path, otherwise return :error"
  def filepath(<<"file://" <> path>>) do
    if File.exists?(path) do
      {:ok, String.to_charlist(path)}
    else
      {:error, :enoexists}
    end
  end

  @impl true
  @doc "Anything that needs to happen after a successful save"
  def post_save(_, _), do: :ok
end
