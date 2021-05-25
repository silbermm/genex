defmodule Genex.Remote.Strategy do
  @moduledoc false

  @type remote_filepath :: binary()
  @type local_filepath :: binary()
  @type peer_id :: binary()
  @type public_key :: binary()

  @callback copy_public_key(remote_filepath, peer_id, public_key) :: :ok | {:error, binary()}
  @callback delete_public_key(remote_filepath, peer_id) :: :ok | {:error, binary()}
  @callback read_peer_public_key(remote_filepath, peer_id) :: binary()

  @callback charlist_from_path(remote_filepath) :: charlist()
  @callback filepath(remote_filepath) :: {:ok, charlist()} | {:error, :enoexists}

  @callback post_save(remote_filepath, local_filepath) :: :ok | {:error, binary()}
end
