defmodule Genex.Application do
  @moduledoc """
  Sets up the application by starting the 
  databse and running any migrations needed
  """

  use Application

  def start(_type, _args) do
    children = [Genex.Repo]

    :ets.new(:profile_lookup, [:set, :public, :named_table])
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
