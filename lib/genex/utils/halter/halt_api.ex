defmodule Genex.Utils.Halter.HalterAPI do
  @moduledoc false

  @callback halt(any()) :: no_return() | :ok
end
