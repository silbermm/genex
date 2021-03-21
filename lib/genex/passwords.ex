defmodule Genex.Passwords do
  @moduledoc """
  The core module for generating, finding, encrypting, decrypting and storing passwords
  """

  alias Genex.Passwords.{Supervisor, Store}
  alias Genex.Data.Credentials
  alias Genex.Remote.Peers

  @encryption Application.compile_env!(:genex, :encryption_module)

  @doc "Generate a password using the Dicware library"
  @spec generate(number()) :: Diceware.Passphrase.t()
  def generate(num \\ 6) do
    Diceware.generate(count: num)
  end

  @doc "Saves the provided credentials"
  @spec save(Credentials.t()) :: :ok | {:error, atom()}
  def save(credentials) do
    with {:ok, encoded} <- Jason.encode(credentials),
         {:ok, encrypted} <- @encryption.encrypt(encoded) do
      Store.save_credentials(credentials, encrypted)
    else
      err -> err
    end
  end

  @doc "Saves the list of credentials for a configured peer"
  @spec save_for_peer(list(Credentials.t()), Genex.Data.Manifest.t(), binary()) ::
          :error | :ok | {:error, :not_found}
  def save_for_peer(creds, peer, public_key_path) do
    Genex.Passwords.Supervisor.load_password_store(peer)

    for cred <- creds do
      with {:ok, encoded} <- Jason.encode(cred),
           {:ok, encrypted} <- @encryption.encrypt(encoded, public_key_path) do
        Genex.Passwords.Supervisor.save_credentials(peer.id, cred, encrypted)
      else
        err -> err
      end
    end

    Genex.Passwords.Supervisor.unload_password_store(peer)
  end

  @doc "List all known accounts"
  @spec list_accounts() :: [String.t()]
  def list_accounts() do
    Store.list_accounts()
    |> account_names()
    |> unique()
  end

  @doc "Find credenials for a specific account"
  @spec find(String.t(), String.t() | nil) :: [Credentials.t()] | {:error, :password} | :error
  def find(account, password) do
    account
    |> Store.find_account()
    |> Enum.map(&decrypt_credentials(&1, password))
    |> Enum.map(&to_credentials/1)
    |> Enum.group_by(&username/1)
    |> Enum.map(&sort_accounts/1)
  rescue
    _e in RuntimeError -> {:error, :password}
  end

  @doc "Get all accounts out of the store"
  @spec all(binary(), Genex.Data.Manifest.t() | nil) ::
          {:ok, list(Credentials.t())} | {:error, :password}
  def all(password, nil \\ nil) do
    {:ok,
     Store.all()
     |> Enum.map(&decrypt_credentials(&1, password))
     |> Enum.map(&to_credentials/1)}
  rescue
    _e in RuntimeError -> {:error, :password}
  end

  def all(password, peer) do
    Genex.Passwords.Supervisor.load_password_store(peer)
    creds = Genex.Passwords.Supervisor.all_credentials(peer.id)
    Genex.Passwords.Supervisor.unload_password_store(peer)

    {:ok,
     creds
     |> Enum.map(&decrypt_credentials(&1, password))
     |> Enum.map(&to_credentials/1)}
  rescue
    _e in RuntimeError -> {:error, :password}
  end

  @spec decrypt_credentials(tuple(), String.t() | nil) :: binary()
  defp decrypt_credentials({_, _, _, creds}, password), do: @encryption.decrypt(creds, password)

  @spec to_credentials(binary()) :: Credentials.t()
  defp to_credentials(raw_creds) do
    raw_creds
    |> Jason.decode!()
    |> Credentials.new()
  end

  @spec username(%{username: String.t()}) :: String.t()
  defp username(%{username: username}), do: username

  @spec sort_accounts(tuple()) :: Credentials.t()
  defp sort_accounts({_username, accounts}) do
    accounts
    |> Enum.sort(&compare_datetime/2)
    |> List.last()
  end

  @spec compare_datetime(Credentials.t(), Credentials.t()) :: boolean
  defp compare_datetime(first, second) do
    case DateTime.compare(first.created_at, second.created_at) do
      :gt -> false
      :lt -> true
      :eq -> true
    end
  end

  @spec account_names(list(tuple())) :: list(String.t())
  defp account_names(accounts), do: Enum.map(accounts, &account_name/1)

  @spec account_name(tuple()) :: String.t()
  defp account_name({account_name, _, _, _}), do: account_name

  @spec unique(list(String.t())) :: list(String.t())
  defp unique(accounts), do: Enum.uniq(accounts)
end
