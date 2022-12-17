defmodule Genex.CLI.Commands.DefaultCommand do
  @moduledoc """

  By default gets all the saved passwords from 
  the data store and displays them (passphrases hidden)
  on the screen.

  OPTIONS
  -------
    --profile       which profile to use

    --help          show this help
  """
  use Prompt.Command

  alias Genex.Settings

  require Logger

  @impl true
  def process(%{help: true}), do: help()

  def process(%{profile: profile}) do
    # validate that the config is good
    config = Settings.get(profile)

    if Settings.is_valid?(config) do
      Ratatouille.run(Genex.CLI.Commands.UI.Default, interval: 250)
    else
      display("Configuration is required before using the application.", color: :red)
      display("Please run genex config --guided first", color: :green)
    end
  end
end
