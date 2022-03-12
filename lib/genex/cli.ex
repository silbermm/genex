defmodule Genex.CLI do
  @moduledoc """
  The CLI entry point
  """

  use Prompt, otp_app: :genex
  alias Genex.Commands.DefaultCommand

  @spec main(list(term)) :: no_return() 
  def main(argv) do
    argv
    |> process([], fallback_module: DefaultCommand)
    |> generate_exit_value()
    |> System.halt()
  end

  defp generate_exit_value(val) when is_integer(val), do: val
  defp generate_exit_value(_), do: -1
end
