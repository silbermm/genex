defmodule Genex.Store.MnesiaResults do
  @moduledoc """
  Results for creating, updating and deleting tables and indexes in Mnesia
  """

  alias __MODULE__

  @type t :: %MnesiaResults{
          errors: [{module(), any()} | {module(), atom(), any()}],
          success: [module() | {module(), atom()}]
        }
  defstruct errors: [], success: []

  def new(), do: %MnesiaResults{}

  def add_error(%MnesiaResults{errors: errors} = results, err),
    do: %MnesiaResults{results | errors: [err | errors]}

  def add_success(%MnesiaResults{success: successes} = results, success),
    do: %MnesiaResults{results | success: [success | successes]}
end
