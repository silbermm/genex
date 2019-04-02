defmodule Genex.Core.Server do
  use GenServer

  require Logger

  alias Genex.Core.Handler

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(port: port) do
    opts = [{:port, port}]

    {:ok, pid} = :ranch.start_listener(:genex_server, :ranch_tcp, opts, Handler, [])

    Logger.info(fn ->
      "Listening for connections on port #{port}"
    end)

    {:ok, pid}
  end

end
