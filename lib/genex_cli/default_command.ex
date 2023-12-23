defmodule GenexCLI.DefaultCommand do
  @moduledoc """
  #{Module.get_attribute(GenexCLI, :moduledoc)}
  """
  use Prompt.Command

  @impl true
  def process(%{help: true}), do: help()

  def process(%{profile: _profile}) do
    help()
  end
end
