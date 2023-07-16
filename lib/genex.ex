defmodule Genex do
  use GenServer, restart: :temporary

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def halt(exit_code) do
    GenServer.cast(__MODULE__, {:halt, exit_code})
  end

  @impl true
  def init(opts) do
    {:ok, opts, {:continue, :start_cli}}
  end

  @impl true
  def handle_continue(:start_cli, state) do
    Genex.CLI.main(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:halt, exit_code}, state) do
    {:stop, exit_code, state}
  end
  
  @impl true
  def terminate(exit_code, state) when is_integer(exit_code) do
    System.halt(exit_code)
    {:noreply, state}
  end

 
  @impl true
  def terminate(_exit_code, state) do
    System.halt(0)
    {:noreply, state}
  end
end
