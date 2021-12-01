defmodule Genex.CLI.Data do
  @moduledoc false

  @data [data: [], cli: %{}]

  def new(), do: @data

  def put(clidata, key, value) do
    data = Keyword.get(clidata, :data)
    data = Keyword.put(data, key, value)
    Keyword.put(clidata, :data, data)
  end

  def get(clidata, key) do
    data = Keyword.get(clidata, :data)
    Keyword.get(data, key)
  end
end
