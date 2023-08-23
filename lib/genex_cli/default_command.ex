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

  @impl true
  def process(%{help: true}), do: help()

  def process(%{profile: _profile}) do
    help()
  end
end
