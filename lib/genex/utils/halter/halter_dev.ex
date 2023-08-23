defmodule Genex.Utils.Halter.HalterDev do
  @moduledoc false
  @behaviour Genex.Utils.Halter.HalterAPI

  require Logger

  @impl true
  def halt(exit_code) do
    Logger.debug("halting with exit code: #{exit_code}")
    :ok
  end
end
