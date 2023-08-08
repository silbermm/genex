defmodule Genex.Application do
  @moduledoc """
  Sets up the application by starting the 
  database and running any migrations needed
  """

  use Application

  @store Genex.Store

  def start(_, env: :dev) do
    with :ok <- @store.init(),
         :ok <- @store.init_tables() do
      Supervisor.start_link([], strategy: :one_for_one)
    else
      {:error, error} -> {:error, error}
    end
  end

  def start(_, _) do
    with :ok <- @store.init(),
         :ok <- @store.init_tables() do
      args = Burrito.Util.Args.get_arguments()
      args = Enum.drop(args, 4)

      children = [{Genex, args}]
      Supervisor.start_link(children, strategy: :one_for_one)
    else
      {:error, error} -> {:error, error}
    end
  end
end
