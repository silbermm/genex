defmodule Genex.Utils.Halter.HalterDev do
  @behaviour Genex.Utils.Halter.HalterAPI

  @impl true
  def halt(), do: :ok
end
