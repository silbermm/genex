defmodule Genex.Core.TcpServer do
  use DynamicSupervisor

  alias Genex.Core.TcpServer

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_child(name), do:
    DynamicSupervisor.start_child(__MODULE__, {TcpServer, name: name})

  def start_server() do
    tcp_server = GenServer.whereis(TcpServer)
    if (tcp_server == nil) do
      start_child(TcpServer)
    else
      {:ok, tcp_server}
    end
  end
end
