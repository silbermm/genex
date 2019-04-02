defmodule Genex.Core.Application do
  use Application

  def start(_type, _args) do
    
    tcp_config = Application.get_env(:genex_core, :server)

    gossip_config = %{config: [
      port: 45892,
      if_addr: "0.0.0.0",
      multicast_addr: "230.1.1.251",
      multicast_ttl: 1]}

    children = [
      {Genex.Core.Gossip, gossip_config},
      {Genex.Core.Server, tcp_config}
    ]
    opts = [strategy: :one_for_one, name: Genex.Core.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
