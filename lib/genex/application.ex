defmodule Genex.Application do
  @moduledoc false
  use Bakeware.Script

  @impl true
  def main(args) do
    application()
    Genex.CLI.main(args)
  end

  def application() do
    opts = [strategy: :one_for_one, name: Genex.Supervisor]

    children = [
      {Genex.Passwords.Store, []},
      {Genex.Passwords.Supervisor, []},
      {Genex.Data.Manifest, []},
      {Genex.Remote.RemoteSystem, []},
      {Genex.Data.Remote.Supervisor, []}
    ]

    Supervisor.start_link(children, opts)
  end
end
