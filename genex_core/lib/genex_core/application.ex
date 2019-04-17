defmodule Genex.Core.Application do
  use Application

  def start(_type, _args) do
    Genex.Core.DataStore.create()
    topologies = %{
      genex: [
        strategy: Genex.Core.Cluster.Gossip,
        config: [
          port: 45892,
          if_addr: "0.0.0.0",
          multicast_addr: "230.1.1.251",
          multicast_ttl: 1
        ]
        # TODO: fix this when I can figure out why libcluster doesn't see my custom MFA
        #connect: {Elixir.Genex.Core.Connection, :connect_client, []}
      ]}

    children = [
      {Cluster.Supervisor, [topologies, [name: Genex.Supervisor]]},
      {Genex.Core.Connection, []},
      {Task.Supervisor, name: Genex.TaskSupervisor}
    ]
    opts = [strategy: :one_for_one, name: Genex.Core.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
