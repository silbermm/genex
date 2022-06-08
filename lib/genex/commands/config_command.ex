defmodule Genex.Commands.ConfigCommand do
  @moduledoc """

  Reads and writes application settings.

  The settings file is located by defaul at:

    $HOME/.genex/config.toml


  OPTIONS
  -------
    --setup   creates the default config file
    --help    show this help

  """

  use Prompt.Command

  @impl true
  def process(%{help: true}), do: help()

  def process(_args) do
    case Genex.AppConfig.read() do
      {:ok, config} ->
        table([["GPG Installed", "GPG Email"], ["yes", config.gpg_email]], header: true)

      {:error, _reason} ->
        # TODO: give the option to create the config
        display("Unable to read config file", error: true, color: :red)
    end
  end
end
