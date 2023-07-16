defmodule Genex.Utils.Halter.HalterAPI do
  @callback halt(any()) :: no_return() | :ok
end
