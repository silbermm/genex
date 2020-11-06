defmodule Genex.System.Client do
  @callback halt(number()) :: number()
  @callback stop(non_neg_integer() | binary()) :: no_return()
  @callback cmd(binary(), [binary()]) :: {Collectable.t(), exit_status :: non_neg_integer()}
  @callback cmd(binary(), [binary()], keyword()) ::
              {Collectable.t(), exit_status :: non_neg_integer()}
end

Mox.defmock(Genex.Support.System, for: Genex.System.Client)
