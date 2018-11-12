defmodule Genex do
  @moduledoc """
  Build a password from readable words using the [Diceware](http://world.std.com/~reinhold/diceware.html) word list.
  """

  alias IO.ANSI

  @wordlist_contents File.read!("priv/diceware.wordlist.asc")

  def main(_opts) do
    generate
    |> IO.puts()
  end

  @doc """
  Generate a password by first creating 6 random numbers and 
  pulling the appropriate word from the dicware word list
  """
  def generate do
    wordlist = wordlist()

    1..6
    |> Enum.map(fn _ -> random_number end)
    |> Enum.map(&find_word(wordlist, &1))
    |> with_colors
  end

  @doc """
  Generates a 5 digit random string from 11111 - 66666
  """
  def random_number do
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
  def wordlist do
    @wordlist_contents
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&tab_split/1)
  end

  @doc """
  Find one word in the wordlist coorelating to the number given.
  """
  def find_word(wordlist, id) do
    {id, word} = Enum.find(wordlist, fn {k, v} -> k == id end)
    word
  end

  defp tab_split(word) do
    [k, v] = String.split(word, "\t")
    {k, v}
  end

  defp single_random, do: Enum.random(1..6)

  defp with_colors(wordlist) do
    [ANSI.cyan(), ANSI.magenta(), ANSI.blue(), ANSI.yellow(), ANSI.green(), ANSI.red()]
    |> Enum.zip(wordlist)
    |> Enum.map(fn {c, w} -> c <> w end)
    |> Enum.join()
  end
end
