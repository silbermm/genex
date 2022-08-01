defmodule Genex.Commands.Show.HelperPanel do
  @moduledoc """
  The top panel showing the context and contextual help
  """

  import Ratatouille.View
  import Ratatouille.Constants

  alias __MODULE__

  @type t :: %{
          config: Genex.AppConfig.t(),
          help: map()
        }

  def render(panel) do
    row do
      column size: 5 do
        label(content: "GPG EMAIL", attributes: [:bold, :underline])

        label do
          text(
            content: panel.config.gpg_email,
            color: :blue,
            attributes: [:bold]
          )
        end
      end

      column size: 8 do
        label(content: "COMMANDS", attributes: [:bold, :underline])

        table do
          for {key, value} <- panel.help do
            table_row do
              table_cell(content: value, color: :green, attributes: [:bold])
              table_cell(content: key)
            end
          end
        end
      end

      column size: 2 do
        label(
          content: """

          .-------.
          | GENEX |
          '-------'
          """
        )
      end
    end
  end

  defstruct [:config, :help]

  def default(config) do
    default_help = [
      {"move", "j/k"},
      {"show password", "space"},
      {"copy password", "c"},
      {"create password", "n/+"},
      {"quit", "q"}
    ]

    %HelperPanel{config: config, help: default_help}
  end

  def update_help(%HelperPanel{} = panel, help_map) do
    %HelperPanel{panel | help: help_map}
  end
end
