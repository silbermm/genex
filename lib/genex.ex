defmodule Genex do
  @moduledoc """
  Build a password from readable words using the [Diceware](http://world.std.com/~reinhold/diceware.html) word list.
  """

  alias IO.ANSI
  alias Jason

  @encryption Application.get_env(:genex, :encryption_module)

  @wordlist_contents File.read!("priv/diceware.wordlist.asc")

  defstruct [:account, :username, :password]

  @doc """
  Generate a password by first creating 6 random numbers and 
  pulling the appropriate word from the dicware word list
  """
  def generate_password do
    wordlist = wordlist()

    1..6
    |> Enum.map(fn _ -> random_number end)
    |> Enum.map(&find_word(wordlist, &1))
  end

  @doc """
  Saves the provided credentials to the designated encyrpted file
  """
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
  def find_credentials(account, password) do
    case @encryption.load(password) do
      {:ok, current_passwords} ->
        current_passwords
        |> Jason.decode!
        |> into_credentials_struct
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

  defp into_credentials_struct(lst) do
    Enum.map(lst, &Genex.Credentials.new/1)
  end

  defp random_number do
    1..5
    |> Enum.map(fn _ -> Task.async(&single_random/0) end)
    |> Task.yield_many()
    |> Enum.map(fn {_task, {:ok, num}} -> num end)
    |> Enum.join()
  end

  @doc """
  Takes the contents of the wordlist and builds a keyword list of
  tuples that contain the id / word combo
  """
  defp wordlist do
    @wordlist_contents
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&tab_split/1)
  end

  @doc """
  Find one word in the wordlist coorelating to the number given.
  """
  defp find_word(wordlist, id) do
    {id, word} = Enum.find(wordlist, fn {k, v} -> k == id end)
    word
  end

  defp tab_split(word) do
    [k, v] = String.split(word, "\t")
    {k, v}
  end

  defp single_random, do: Enum.random(1..6)
end
