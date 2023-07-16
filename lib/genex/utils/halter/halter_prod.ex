defmodule Genex.Utils.Halter.HalterProd do
  @behaviour Genex.Utils.Halter.HalterAPI

  @impl true
  def halt(exit_value) do
    Genex.halt(exit_value)
  end
end
