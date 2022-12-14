defmodule Genex.Application do
  @moduledoc """
  Sets up the application by starting the 
  databse and running any migrations needed
  """

  use Application

  def start(_type, _args) do
    children = [Genex.Repo]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
