defmodule Genex.Commands.TestCommand do
  use Prompt.Command

  @impl true
  def process(params) do
    IO.inspect params
    Ratatouille.run(Genex.CLI.Counter)
  end
end
