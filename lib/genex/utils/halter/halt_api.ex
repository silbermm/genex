defmodule Genex.Utils.Halter.HalterAPI do
  @callback halt() :: no_return() | :ok
end
