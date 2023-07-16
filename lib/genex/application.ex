defmodule Genex.Application do
  @moduledoc """
  Sets up the application by starting the 
  database and running any migrations needed
  """

  use Application

  def start(_type, _args) do

    args = Burrito.Util.Args.get_arguments()
    args = Enum.drop(args, 4)

    children = [Genex.Repo, {Genex, args}]

    :ets.new(:profile_lookup, [:set, :public, :named_table])
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
