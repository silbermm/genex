defmodule Genex.Remote.LocalPeers do
  @moduledoc """
  Peers are other systems that we trust to send our passwords too and that typically trust us back. In this way
  we can share our passwords bi-directionally and in a decentralized way. 
  """

  alias Genex.Data.Manifest

  @home Application.compile_env!(:genex, :genex_home)
  @encryption Application.compile_env!(:genex, :encryption_module)

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

  def list_for_remote(remote) do
    Manifest.get_peers()
    |> Enum.reject(fn p -> p.remote.name != remote.name end)
  end

  def encrypt_for_peer(peer, local_creds) do
    # encrypt all passwords using the public key of the peer
    # TODO: start up the process for the peer store
    IO.inspect("starting passwords for #{peer.id}")
    {:ok, pid} = Genex.Remote.Data.Passwords.start_link(peer: peer)

    for cred <- local_creds do
      IO.inspect("encrypting passwords for #{peer.id}")

      with {:ok, encoded} <- Jason.encode(cred),
           {:ok, encrypted} <- @encryption.encrypt(encoded, public_key_path(peer.id)) do
        IO.inspect("saving passwords for #{peer.id}")

        IO.inspect(GenServer.whereis(pid), label: "GENSERVER")

        Genex.Remote.Data.Passwords.save_credentials(
          pid,
          cred.account,
          cred.username,
          cred.created_at,
          encrypted
        )
      else
        err -> err
      end
    end

    IO.inspect("stopping passwords for #{peer.id}")
    Genex.Remote.Data.Passwords.stop(pid)
  end

  def load_from_peer(_peer_id) do
    # load peer encrypted passwords for syncing
  end

  def public_key_path(peer_id) do
    @home
    |> Path.join(peer_id)
    |> Path.join("public_key.pem")
  end

  def passwords_path(peer_id) do
    @home
    |> Path.join(peer_id)
    |> Path.join("passwords")
  end
end
