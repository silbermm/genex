defmodule Genex.Utils.Halter.HalterProd do
  @moduledoc false
  @behaviour Genex.Utils.Halter.HalterAPI

  @impl true
  def halt(exit_value) do
    :mnesia.stop()
    Genex.halt(exit_value)
  end
end
