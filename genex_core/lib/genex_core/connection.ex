defmodule Genex.Core.Connection do
  use GenServer
  alias Genex.Core.DataStore
  alias __MODULE__

  defstruct [:trusted_devices, :non_trusted_devices]

  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @impl true
  def init(_args) do
    # get all trusted devices and set in state
    all_trusted = case DataStore.get_all_trusted_devices() do
      {:ok, devices} -> devices
      _ -> []
    end
    {:ok, %Connection{trusted_devices: all_trusted, non_trusted_devices: []}}
  end

  def handle_call({:connect, n, pub}, _from, state) do
    if(node_trusted?(n, pub, state)) do
      IO.inspect("NODE TRUSTED (#{n})", label: "CONNECT_CLIENT")
      {:reply, Node.connect(n), state}
    else
      IO.inspect("NODE NOT TRUSTED (#{n})", label: "CONNECT_CLIENT")
      non_trusted = state.non_trusted_devices ++ n
      {:reply, false, %{state | non_trusted_devices: non_trusted}}
    end
  end

  def handle_cast({:trust, n, pub, replicate?}, _from, state) do
    DataStore.add_trusted_device(n, pub)
    if (replicate) do
      {Genex.TaskSupervisor, n}
      |> Task.Supervisor.async(Genex.Core.Connect, trust_node, [node(), "1234", false])
    end
    {:no_reply, %{state | [state.trusted_devices | {n, pub}]}}
  end

  def connect([n], public_key) do
    GenServer.call(__MODULE__, {:connect, n, public_key})
  end

  def trust_node(node_name, public_key, replicate // false) do
    GenServer.cast(__MODULE__, {:trust, n, public_key, replicate})
  end

  defp node_trusted?(node_name, public_key, %{trusted_devices: trusted_devices} = _state) do
    Enum.any?(trusted_devices, fn {name, pub_key} ->
      name == node_name && pub_key == public_key
    end)
  end

  defp remote_supervisor(recipient) do
    {Chat.TaskSupervisor, recipient}
  end
end
