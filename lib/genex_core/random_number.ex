defmodule Genex.Core.RandomNumber do

  @doc "Generate a randomn number string from 11111 to 66666"
  @spec random_number :: number()
  def random_number() do
    1..5
    |> Enum.map(fn _ -> Task.async(&single_random/0) end)
    |> Task.yield_many()
    |> Enum.map(fn {_task, {:ok, num}} -> num end)
    |> Enum.join()
  end

  defp single_random, do: Enum.random(1..6)
end
