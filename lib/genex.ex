defmodule Genex do
  @moduledoc """
  Build a password from readable words using 
  the [Diceware](http://world.std.com/~reinhold/diceware.html) word list
  and save it to an encrypted file.
  """

  alias Jason
  alias Genex.Data.Credentials

  @encryption Application.compile_env!(:genex, :encryption_module)
  @store Application.compile_env(:genex, :store_module, Genex.Data.Passwords)

  @doc """
  Generate a password using the Dicware library
  """
  @spec generate_password(number()) :: Diceware.Passphrase.t()
  def generate_password(num \\ 6) do
    Diceware.generate(count: num)
  end

  @doc """
  Saves the provided credentials
  """
  @spec save_credentials(Credentials.t()) :: :ok | {:error, atom()}
  def save_credentials(credentials) do
    with {:ok, encoded} <- Jason.encode(credentials),
         {:ok, encrypted} <- @encryption.encrypt(encoded) do
      @store.save_credentials(
        credentials.account,
        credentials.username,
        credentials.created_at,
        encrypted
      )
    else
      err -> err
    end
  end

  @doc """
  List all known accounts
  """
  def list_accounts() do
    @store.list_accounts()
    |> account_names()
    |> unique()
  end

  @doc """
  Find credenials for a specific account
  """
  @spec find_credentials(String.t(), String.t() | nil) ::
          [Credentials.t()] | {:error, :password} | :error
  def find_credentials(account, password) do
    account
    |> @store.find_account()
    |> Enum.map(fn {_, _, _, creds} -> @encryption.decrypt(creds, password) end)
    |> Enum.map(fn creds ->
      creds
      |> Jason.decode!()
      |> Credentials.new()
    end)
    |> Enum.group_by(fn c -> Map.get(c, :username) end)
    |> Enum.map(&sort_accounts/1)
  rescue
    _e in RuntimeError -> {:error, :password}
  end

  def all(password) do
    data =
      @store.all()
      |> Enum.map(fn {account, username, date, creds} -> @encryption.decrypt(creds, password) end)
      |> Enum.map(fn creds ->
        creds
        |> Jason.decode!()
        |> Credentials.new()
      end)

    {:ok, data}
  rescue
    _e in RuntimeError -> {:error, :password}
  end

  defp sort_accounts({_u, accnts}) do
    accnts
    |> Enum.sort(&compare_datetime/2)
    |> List.last()
  end

  defp compare_datetime(first, second) do
    case DateTime.compare(first.created_at, second.created_at) do
      :gt -> false
      :lt -> true
      :eq -> true
    end
  end

  defp account_names(accounts), do: Enum.map(accounts, &account_name/1)
  defp account_name({account_name, _, _, _}), do: account_name

  defp unique(accounts), do: Enum.uniq(accounts)
end
