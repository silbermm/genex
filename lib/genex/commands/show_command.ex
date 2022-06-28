defmodule Genex.Commands.ShowCommand do
  @moduledoc """

  Show passwords

  OPTIONS
  -------
    --help    show this help

  """

  use Prompt.Command

  @impl true
  def process(%{help: true}), do: help()

  def process(_args) do
    case Genex.AppConfig.read() do
      {:ok, config} ->
        #Ratatouille.Runtime.Supervisor.start_link(runtime: [app: Genex.Commands.ShowCommandAdvanced])
        Ratatouille.run(Genex.Commands.ShowCommandAdvanced, [config: config])

      {:error, _reason} ->
        display("Unable to read config file", error: true, color: :red)
    end
  end
end
