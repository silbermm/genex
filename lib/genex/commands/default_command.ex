defmodule Genex.Commands.DefaultCommand do
  @moduledoc false

  use Prompt.Command

  require Logger

  @impl true
  def init(argv) do

    argv
    |> OptionParser.parse_head(
      strict: [save: :boolean, length: :integer],
      aliases: [s: :save, l: :length]
    )
    |> parse_opts()
  end

  @impl true
  def process(opts) do
    # generate a password using diceware
    generated = Diceware.generate(count: opts.length)

    generated
    |> Diceware.with_colors()
    |> maybe_show_choices(opts)
  end

  defp maybe_show_choices(passphrase, %{save: true} = opts) do
    passphrase
    |> choice(accept: "a", regenerate: "r")
    |> case do
      :regenerate ->
        # when regenerating, lets clear the previous password
        # and replace it with a new one
        _ = Prompt.Position.clear_lines(1)
        process(opts)

      :accept ->
        # when accepted
        #   * put in clipboard?
        #   * mask the line?
        :ok

      _ ->
        {:error, :invalid}
    end
  end

  defp maybe_show_choices(passphrase, _) do
    display(passphrase)
  end

  defp parse_opts({[], _, _}), do: %{save: false, length: 6}

  defp parse_opts({opts, _, _}) do
    save? = Keyword.get(opts, :save, false)
    length = Keyword.get(opts, :length, 6)
    %{save: save?, length: length}
  end
end
