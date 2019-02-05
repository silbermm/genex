defmodule Genex do
  @moduledoc """
  Build a password from readable words using the [Diceware](http://world.std.com/~reinhold/diceware.html) word list.
  """

  alias IO.ANSI
  @encryption Application.get_env(:genex, :encryption)

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
  def save_credentials(credentials) do
    line = "#{credentials.account},#{credentials.username},#{credentials.password}"

    with {:ok, current_passwords} <- @encryption.load(),
         :ok <- validate_unique(credentials.account, credentials.username, current_passwords) do
      new_passwords = current_passwords <> line
      @encryption.save(new_passwords)
      :ok
    else
      {:error, :noexists} ->
        @encryption.save(line)

      {:error, :not_unique} ->
        {:error, :not_unique}

      w ->
        :error
    end
  end

  @doc """
  Find credenials for a specific account
  """
  def find_credentials(account) do
    case @encryption.load() do
      {:ok, current_passwords} ->
        current_passwords
        |> String.trim()
        |> String.split("\n")
        |> Enum.map(&into_password_struct/1)
        |> Enum.filter(fn x -> x.account == account end)

      _ ->
        :error
    end
  end

  defp validate_unique(account, username, current) do
    account
    |> find_credentials
    |> Enum.find(fn x -> x.username == username end)
    |> case do
      nil -> :ok
      _ -> {:error, :not_unique}
    end
  end

  defp into_password_struct(str) do
    [account, username, password] = String.split(str, ",")
    Genex.Credentials.new(account, username, password)
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
