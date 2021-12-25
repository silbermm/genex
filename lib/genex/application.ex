defmodule Genex.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_, _) do
    _ = application()
    # this returns a list of strings
    # args = Burrito.Util.Args.get_arguments()
    # Genex.CLI.main(args)
  end

  def application() do
    opts = [strategy: :one_for_one, name: Genex.Supervisor]

    children = []

    Supervisor.start_link(children, opts)
  end
end
