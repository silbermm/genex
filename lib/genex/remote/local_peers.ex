defmodule Genex.Remote.LocalPeers do
  @moduledoc """
  Peers are other systems that we trust to send our passwords too and that typically trust us back. In this way
  we can share our passwords bi-directionally and in a decentralized way. 
  """

  alias Genex.Data.Manifest

  @home Application.compile_env!(:genex, :genex_home)

  @type peer :: %{
          id: String.t(),
          public_key: binary(),
          hostname: String.t(),
          os: String.t()
        }

  @doc """
  Adds a trusted peer and returns the peers unique id
  """
  def add(manifest, public_key) do
    # write public key to disc
    # file should live in .genex/#{peer_id}/public_key.pem
    folder = Path.join(@home, manifest.id)

    if !File.exists?(folder) do
      _ = File.mkdir(folder)
    end

    case File.write(public_key_path(manifest.id), public_key) do
      :ok ->
        _ = Manifest.add_peer(manifest)
        {:ok, manifest.id}

      err ->
        IO.inspect(err)
        {:error, :nowrite}
    end
  end

  def remove do
    # remove public key from disc
    #
    # remove data from manifest
  end

  @doc """
  List all known trusted peers
  """
  def list(), do: Manifest.get_peers()

  def encrypt_for_peer(_peer_id, _local_passwords) do
    # encrypt all passwords using the public key of the peer
    # save to a peer specific file for uploading to a server
  end

  def load_from_peer(_peer_id) do
    # load peer encrypted passwords for syncing
  end

  def public_key_path(peer_id) do
    @home
    |> Path.join(peer_id)
    |> Path.join("public_key.pem")
  end
end
