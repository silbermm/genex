defmodule Genex.CLI.Command do
  @moduledoc """
  Defines the behaviour for a command.

  We expect to `parse/1` the command line options and get
  back a struct that is passed to `parse/1` which handles 
  the all the side effects of the command itself.
  """
  @callback parse(list(String.t())) :: term
  @callback process(term) :: :ok | {:error, binary()}
end
