defmodule Genex do
  @moduledoc """
  Build a password from readable words using 
  the [Diceware](http://world.std.com/~reinhold/diceware.html) word list
  and save it to an encyrpted file.
  """

  alias Jason
  alias Genex.Data.Credentials

  @encryption Application.get_env(:genex, :encryption_module)

  @doc """
  Generate a password by first creating 6 random numbers and
  pulling the appropriate word from the dicware word list
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
      Genex.Store.save_credentials(
        credentials.account,
        credentials.username,
        credentials.created_at,
        encrypted
      )
    else
      :error ->
        IO.inspect("ERROR")

      err ->
        IO.inspect(err)
    end
  end

  @doc """
  Find credenials for a specific account
  """
  @spec find_credentials(String.t(), String.t() | nil) ::
          [Credentials.t()] | {:error, :password} | :error
  def find_credentials(account, password) do
    account
    |> Genex.Store.find_account()
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
end
