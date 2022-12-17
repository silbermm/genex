defmodule Genex.CLI.Commands.UI.ColorizedPassphrase do
  @moduledoc """
  Render the passphrase with colors
  """

  import Ratatouille.View
  import Ratatouille.Constants

  @colors [color(:red), color(:blue), color(:green), color(:yellow)]

  def render(pass) do
    number_of_color_lists = div(pass.count, Enum.count(@colors))
    extra_colors = rem(pass.count, Enum.count(@colors))

    colors =
      Enum.reduce(0..number_of_color_lists, [], fn _x, acc ->
        acc ++ @colors
      end)

    color_list = colors ++ Enum.take(@colors, extra_colors)

    Enum.with_index(pass.words, fn element, index ->
      text(content: element, color: Enum.at(color_list, index))
    end)
  end
end
