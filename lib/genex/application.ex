defmodule Genex.Application do
  @moduledoc false
  use Bakeware.Script

  @impl true
  def main(args) do
    opts = [strategy: :one_for_one, name: Genex.Supervisor]
    children = [{Genex.Data.Passwords, []}, {Genex.Data.Manifest, []}]
    Supervisor.start_link(children, opts)

    Genex.CLI.main(args)
  end
end
