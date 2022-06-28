defmodule Genex.ReleaseTask do
  def run(args) do
    Application.ensure_all_started(:genex)
    Genex.CLI.main(args)
  end
end
