defmodule GenexTest.Diceware do
  use ExUnit.Case
  doctest Genex.Diceware

  alias Genex.Diceware

  setup do
    wordlist = Diceware.wordlist()
    [wordlist: wordlist]
  end

  test "wordlist file is read correctly", %{wordlist: wordlist} do
    assert Enum.count(wordlist) == 7776
  end

  test "wordlist file is parsed correctly", %{wordlist: wordlist} do
    assert List.first(wordlist) == {"11111", "a"}
  end

  test "finds specific word in the list", %{wordlist: wordlist} do
    assert Diceware.find_word(wordlist, "11111") == "a"
    assert Diceware.find_word(wordlist, "65255") == "z"
  end
end
