defmodule Genex.Commands.Show.New do
  @moduledoc """
  Rendering for creating a new password in the TUI
  """

  import Ratatouille.View
  import Ratatouille.Constants

  def render(model) do
    overlay do
      panel title: "New Password - ESC to cancel" do
        row do
          column size: 9 do
            label(content: model.new.account <> "▌")
          end
        end
      end
    end
  end
end
