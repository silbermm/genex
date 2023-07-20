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
      :ets.new(:profile_lookup, [:set, :public, :named_table])
      Supervisor.start_link([], strategy: :one_for_one)
    else
      {:error, error} -> {:error, error}
    end
  end

  def start(_, _) do
    args = Burrito.Util.Args.get_arguments()
    args = Enum.drop(args, 4)

    children = [Genex.Repo, {Genex, args}]

    :ets.new(:profile_lookup, [:set, :public, :named_table])
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
