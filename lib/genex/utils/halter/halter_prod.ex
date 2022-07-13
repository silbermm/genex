defmodule Genex.Utils.Halter.HalterProd do
  @behaviour Genex.Utils.Halter.HalterAPI

  @impl true
  def halt() do
    :mnesia.stop()
    System.halt(0)
  end
end
