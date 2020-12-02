defmodule Genex.Application do
  @moduledoc false
  use Bakeware.Script

  @impl true
  def main(args) do
    opts = [strategy: :one_for_one, name: Genex.Supervisor]
    children = [{Genex.Store.ETS, []}]
    Supervisor.start_link(children, opts)

    Genex.CLI.main(args)
    0
  end
end
