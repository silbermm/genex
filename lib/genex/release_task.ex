defmodule Genex.ReleaseTask do
  @moduledoc """
  This exists as a way to run the CLI `main` function
  from a release.
  """
  def run(args) do
    Application.ensure_all_started(:genex)
    Genex.CLI.main(args)
  end
end
