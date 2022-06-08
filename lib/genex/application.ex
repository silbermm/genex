defmodule Genex.Application do
  use Application

  @store Application.compile_env!(:genex, :store)

  @impl true
  def start(_type, _args) do
    with :ok <- ensure_dir_exists(),
         :ok <- @store.init(),
         :ok <- @store.init_tables() do
      children = []
      Supervisor.start_link(children, strategy: :one_for_one)
    else
      {:error, error} -> {:error, error}
    end
  end

  defp ensure_dir_exists() do
    #TODO: make sure the genex directory exists
    :ok
  end
end
