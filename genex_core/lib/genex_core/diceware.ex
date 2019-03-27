defmodule GenexCore.Diceware do
  @moduledoc """
  Diceware wordlist functions
  """

  @wordlist_contents File.read!("priv/diceware.wordlist.asc")

  @doc "Build a list of tuples {line number, word} from diceware word list"
  @spec wordlist :: [tuple()]
  def wordlist do
    @wordlist_contents
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&tab_split/1)
  end

  @doc "Given a number from 11111 to 66666, find the cooresponding diceware word"
  @spec find_word([tuple()], binary()) :: binary()
  def find_word(wordlist, id) do
    {id, word} = Enum.find(wordlist, fn {k, v} -> k == id end)
    word
  end

  defp tab_split(word) do
    [k, v] = String.split(word, "\t")
    {k, v}
  end

end
