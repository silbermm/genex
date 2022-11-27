defmodule Genex.Commands.DefaultCommand do
  @moduledoc """

  By default gets all the saved passwords from 
  the data store and displays them (passphrases hidden)
  on the screen.

  OPTIONS
  -------
    --help          show this help
  """
  use Prompt.Command

  require Logger

  @impl true
  def process(%{help: true}), do: help()
  def process(_args), do: Ratatouille.run(Genex.Commands.UI.Default, interval: 250)
end
