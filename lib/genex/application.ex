defmodule Genex.Application do
  @moduledoc false
  use Application

  @impl Application
  def start(_type, env: :test) do
    children = []

    opts = [strategy: :one_for_one, name: Genex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl Application
  def start(_type, _args) do
    children = [
      {Genex.Store.ETS, []}
    ]

    opts = [strategy: :one_for_one, name: Genex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl Application
  def stop(_) do
    IO.puts("stopping")
  end
end
