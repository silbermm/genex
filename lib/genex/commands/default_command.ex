defmodule Genex.Commands.DefaultCommand do
  @moduledoc """
  genex - asdfasdf
  """
  use Prompt.Command

  @impl true
  def init(_cli_options) do
    # for now, lets assume no options are supported to the bare command
    # eventually we'll want an option for the size of the password
    # maybe even take options for special charactors, capitol, etc
    %{}
  end

  @impl true
  def process(term) do
    # generate a password using diceware
    generated = Diceware.generate()

    generated
    |> Diceware.with_colors()
    |> choice(accept: "a", regenerate: "r")
    |> case do
      :regenerate ->
        # when regenerating, lets clear the previous password
        # and replace it with a new one
        _ = Prompt.Position.clear_lines(1)
        process(term)
      :accept -> 
        # when accepted
        #   * put in clipboard?
        #   * mask the line?
        :ok
      _ -> {:error, :invalid}
    end
  end
end
