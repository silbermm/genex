defmodule Genex.Commands.UI.HelperPanel do
  @moduledoc """
  The top panel showing the context and contextual help
  """

  import Ratatouille.View

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

        label(content: "")

        label(content: "PASSWORD LENGTH", attributes: [:bold, :underline])

        label do
          text(
            content: "#{panel.config.password_length}",
            color: :blue,
            attributes: [:bold]
          )
        end
      end

      column size: 4 do
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

      column size: 4 do
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
      {"reveal", "space"},
      {"copy", "c"},
      {"new", "n/+"},
      {"delete", "d/-"},
      {"quit", "q"}
    ]

    %HelperPanel{config: config, help: default_help}
  end

  def update_help(%HelperPanel{} = panel, help_map) do
    %HelperPanel{panel | help: help_map}
  end
end
