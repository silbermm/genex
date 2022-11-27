defmodule Genex.Passwords.PasswordPushWorker do
  @moduledoc """
  Background job that pushes passwords to the remote server
  """
  use GenServer, restart: :transient
  require Logger

  @store Application.compile_env!(:genex, :store)

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(config) do
    Logger.debug("initializing PasswordPushWorker")
    {:ok, config, {:continue, :get_passwords}}
  end

  @impl true
  def handle_continue(:get_passwords, state) do
    Logger.debug("get passwords")

    case @store.all_passwords() do
      {:ok, passwords} ->
        {:noreply, Map.put(state, :data, passwords), {:continue, :encrypt}}

      _ ->
        Logger.error("unable to get passwords")
        {:stop, :shutdown, state}
    end
  end

  def handle_continue(:encrypt, state) do
    Logger.debug("encrypt passwords")
    # encrypt passwords for pushing up
    json = Jason.encode!(state.data)

    case GPG.encrypt(state.email, json) do
      {:ok, encrypted} -> {:noreply, Map.put(state, :data, encrypted), {:continue, :send}}
      _ -> {:stop, :shutdown}
    end
  end

  def handle_continue(:send, state) do
    Logger.debug("send passwords")
    # send data to remote
    case Req.post("#{state.url}/api/passwords",
           json: %{passwords: state.data},
           auth: {:bearer, state.token}
         ) do
      {:ok, res} ->
        Logger.info("successfully sent data: #{inspect(res)}")

      err ->
        Logger.error("error when sending #{inspect(err)}")
    end

    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, _state) do
    Logger.debug("done")
    :ok
  end
end
