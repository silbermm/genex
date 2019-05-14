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

  @encryption Application.get_env(:genex_cli, :encryption_module)
  @random Application.get_env(:genex_cli, :random_number_module)

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
    filename = Environment.load_variable("GENEX_PASSWORDS", :passwords_file)

    {:ok, encrypted} = @encryption.encrypt(credentials.password)
    creds = Credentials.add_encrypted_password(credentials, encrypted)
    with {:ok, file} <- File.read(filename),
         {:ok, d} <- Jason.decode(file) do
      data = Jason.encode!(d ++ [creds])
      File.write(filename, data);
    else
      {:error, :enoent} -> File.write(filename, Jason.encode!([creds]))
      err -> IO.inspect(err, label: "ERRORED")
    end
  end

  def show_credentials(password) do
    filename = Environment.load_variable("GENEX_PASSWORDS", :passwords_file)
    with {:ok, file} <- File.read(filename),
         {:ok, d} <- Jason.decode(file) do
      passwords = Enum.map(d, fn p -> @encryption.decrypt(Map.get(p, "encrypted_password"), password) end)
      IO.inspect(passwords)
    else
      err -> IO.inspect(err, label: "ERRORED")
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
