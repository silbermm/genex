defmodule Genex do
  @moduledoc """
  Build a password from readable words using 
  the [Diceware](http://world.std.com/~reinhold/diceware.html) word list
  and save it to an encyrpted file.
  """

  alias Jason
  alias Genex.Data.Credentials
  alias Genex.PasswordFile

  @encryption Application.get_env(:genex, :encryption_module)

  @doc """
  Generate a password by first creating 6 random numbers and
  pulling the appropriate word from the dicware word list
  """
  @spec generate_password(number()) :: [Diceware.Passphrase.t()]
  def generate_password(num \\ 6) do
    Diceware.generate(count: num)
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

  defp decrypt_passwords({_u, accnts}, password) do
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
end
