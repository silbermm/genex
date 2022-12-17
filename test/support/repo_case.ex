defmodule Genex.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Genex.Repo

      import Ecto
      import Ecto.Query
      import Genex.RepoCase

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Genex.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Genex.Repo, {:shared, self()})
    end

    :ok
  end
end
