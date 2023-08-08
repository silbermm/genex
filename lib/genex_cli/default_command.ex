defmodule GenexCLI.DefaultCommand do
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
  alias Genex.Configuration
  require Logger

  @impl true
  def process(%{help: true}), do: help()

  def process(%{profile: profile}) do
    # validate that the configuration is good
    config = Configuration.get(profile)

    if Configuration.is_valid?(config) do
      display("Config is good")
      0
    else
      display("Configuration is required before using the application.", color: :red)
      display("Please run \"genex config --guided\" first", color: :green)
      1
    end
  end
end
