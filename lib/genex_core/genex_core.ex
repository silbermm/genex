defmodule Genex.Core do
  @moduledoc """
  Build a password from readable words using 
  the [Diceware](http://world.std.com/~reinhold/diceware.html) word list
  and save it to an encyrpted file.
  """

  alias Jason
  alias Genex.Core.Credentials
  alias Genex.Core.Diceware
  alias Genex.Core.Environment
  alias Genex.Core.PasswordFile

  @encryption Application.get_env(:genex_cli, :encryption_module)
  @random Application.get_env(:genex_cli, :random_number_module)

  @doc """
  Generate a password by first creating 6 random numbers and
  pulling the appropriate word from the dicware word list
  """
  @spec generate_password(number()) :: [String.t()]
  def generate_password(num \\ 6) do
    wordlist = Diceware.wordlist()

    1..num
    |> Enum.map(fn _ -> @random.random_number() end)
    |> Enum.map(&Diceware.find_word(wordlist, &1))
  end

  @doc """
  Saves the provided credentials to the designated encyrpted file
  """
  @type save_creds_return :: :ok | {:error, atom()}
  @spec save_credentials(Credentials.t()) :: save_creds_return
  def save_credentials(credentials) do
    {:ok, encrypted} = @encryption.encrypt(credentials.password)
    creds = Credentials.add_encrypted_password(credentials, encrypted)

    case PasswordFile.load() do
      {:ok, data} ->
        combined = data ++ [creds]
        data = Jason.encode!(combined)
        PasswordFile.write(data)

      :error ->
        PasswordFile.write(Jason.encode!([creds]))
    end
  end

  @doc """
  Find credenials for a specific account
  """
  @spec find_credentials(String.t(), String.t() | nil) ::
          [Credentials.t()] | {:error, :password} | :error
  def find_credentials(account, password) do
    case PasswordFile.load() do
      {:ok, data} ->
        try do
          data
          |> Stream.filter(fn c -> Map.get(c, "account") == account end)
          |> Stream.map(&Credentials.new/1)
          |> Enum.group_by(fn c -> Map.get(c, :username) end)
          |> Enum.map(&decrypt_passwords(&1, password))
        rescue
          _e in _ -> {:error, :password}
        end

      :error ->
        :error
    end
  end

  defp decrypt_passwords({u, accnts}, password) do
    account =
      accnts
      |> Enum.sort(&compare_datetime/2)
      |> List.last()

    {:ok, pass} = @encryption.decrypt(account.encrypted_password, password)
    Credentials.add_password(account, pass)
  end

  defp compare_datetime(first, second) do
    case DateTime.compare(first.created_at, second.created_at) do
      :gt -> false
      :lt -> true
      :eq -> true
    end
  end

  defp validate_unique(%Credentials{account: account, username: username, password: _}, current) do
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
