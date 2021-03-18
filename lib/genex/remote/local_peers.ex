defmodule Genex.Remote.LocalPeers do
  @moduledoc """
  Peers are other systems that we trust to send our passwords too and that typically trust us back. In this way
  we can share our passwords bi-directionally and in a decentralized way. 
  """

  alias Genex.Manifest

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
    # write public key to disk
    # file should live in .genex/#{peer_id}/public_key.pem
    folder = Path.join(@home, manifest.id)

    if !File.exists?(folder) do
      _ = File.mkdir(folder)
    end

    case File.write(public_key_path(manifest.id), public_key) do
      :ok ->
        _ = Manifest.Store.add_peer(manifest)
        {:ok, manifest.id}

      err ->
        IO.inspect(err)
        {:error, :nowrite}
    end
  end

  def remove do
    # remove public key from disk
    #
    # remove data from manifest
  end

  @doc """
  List all known trusted peers
  """
  def list(), do: Manifest.Store.get_peers()

  def list_for_remote(remote) do
    Manifest.Store.get_peers()
    |> Enum.reject(fn p -> p.remote.name != remote.name end)
  end

  def encrypt_for_peer(peer, local_creds) do
    Genex.Passwords.Supervisor.load_password_store(peer)

    for cred <- local_creds do
      with {:ok, encoded} <- Jason.encode(cred),
           {:ok, encrypted} <- @encryption.encrypt(encoded, public_key_path(peer.id)) do
        Genex.Passwords.Supervisor.save_credentials(
          peer.id,
          cred.account,
          cred.username,
          cred.created_at,
          encrypted
        )
      else
        err -> err
      end
    end

    Genex.Passwords.Supervisor.unload_password_store(peer)
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
