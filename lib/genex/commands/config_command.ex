defmodule Genex.Commands.ConfigCommand do
  @moduledoc """

  Reads and writes application settings.

  The settings file is located by defaul at:

    $HOME/.genex/config.toml


  OPTIONS
  -------
    --set <property>          set a config property
    --set <property>:<value>  set a config property to <value>

    --help                    show this help

  """

  use Prompt.Command

  alias Genex.AppConfig

  @impl true
  def process(%{help: true}), do: help()

  def process(%{set: key}) when key != "" do
    # validate property is valid
    with true <- AppConfig.valid_key?(key),
         {:ok, config} <- AppConfig.read(),
         value <- text("Set #{key} to", trim: true) do
      # set the value in the config file 
      config
      |> AppConfig.update(key, value)
      |> AppConfig.write()
    else
      false -> display("#{key} is not a valid config key", color: :red)
      _e -> display("Unable to set the config value", color: :red)
    end
  end

  def process(_args) do
    case Genex.AppConfig.read() do
      {:ok, config} ->
        table([["GPG Installed", "GPG Email"], ["yes", config.gpg_email]], header: true)

      {:error, _reason} ->
        display("Unable to read config file", error: true, color: :red)
    end
  end
end
