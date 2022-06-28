defmodule Genex.ReleaseTask do
  def run() do
    # Eval commands needs to start the app before
    # Or Application.load(:my_app) if you can't start it
    Application.ensure_all_started(:genex)
    Genex.CLI.main()
  end

  def run(args) do
    # Eval commands needs to start the app before
    # Or Application.load(:my_app) if you can't start it
    Application.ensure_all_started(:genex)
    Genex.CLI.main(args)
  end
end
