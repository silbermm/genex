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
        Ratatouille.run(Genex.Commands.ShowCommandAdvanced, [config: config])

      {:error, _reason} ->
        # TODO: give the option to create the config
        display("Unable to read config file", error: true, color: :red)
    end
  end
end
