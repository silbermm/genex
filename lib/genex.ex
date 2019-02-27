defmodule Genex do
  @moduledoc """
  Build a password from readable words using 
  the [Diceware](http://world.std.com/~reinhold/diceware.html) word list
  and save it to an encyrpted file.
  """

  alias IO.ANSI
  alias Jason
  alias Genex.Credentials
  alias Genex.Diceware

  @encryption Application.get_env(:genex, :encryption_module)
  @random Application.get_env(:genex, :random_number_module)

  @doc """
  Generate a password by first creating 6 random numbers and
  pulling the appropriate word from the dicware word list
  """
  @spec generate_password(number()) :: [String.t]
  def generate_password(num \\ 6) do
    wordlist = Diceware.wordlist()

    1..num
    |> Enum.map(fn _ -> @random.random_number() end)
    |> Enum.map(&Diceware.find_word(wordlist, &1))
  end

  @doc """
  Saves the provided credentials to the designated encyrpted file
  """
  @type save_creds_return :: :ok | {:error, :not_unique | :nokeydecrypt | :password} | :error
  @spec save_credentials(Credentials.t(), binary() | nil) :: save_creds_return
  def save_credentials(credentials, password) do

    with {:ok, current_passwords} <- @encryption.load(password),
         {:ok, current_json} <- Jason.decode(current_passwords),
         :ok <- validate_unique(credentials, current_json) do
      n = current_json ++ [credentials]
      encoded = Jason.encode!(n)
      @encryption.save(encoded)
      :ok
    else
      {:error, :noexists} ->
        line = Jason.encode!([credentials])
        @encryption.save(line)

      {:error, :not_unique} ->
        {:error, :not_unique}

      {:error, :nokeydecrypt} ->
        {:error, :password}

      _ -> :error
    end
  end

  @doc """
  Find credenials for a specific account
  """
  @spec find_credentials(String.t, String.t | nil) :: [Credentials.t()] | {:error, :password} | :error
  def find_credentials(account, password) do
    case @encryption.load(password) do
      {:ok, current_passwords} ->
        current_passwords
        |> Jason.decode!
        |> Enum.map(&Credentials.new/1)
        |> Enum.filter(fn x -> x.account == account end)

      {:error, :nokeydecrypt} -> {:error, :password}
      _ -> :error
    end
  end

  defp validate_unique(%Genex.Credentials{account: account, username: username, password: _}, current) do
    current
    |> Enum.find(fn x ->
      Map.get(x, "username") == username && Map.get(x, "account") == account
    end)
    |> case do
      nil -> :ok
      _ -> {:error, :not_unique}
    end
  end
end
