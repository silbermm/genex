defmodule Genex.Commands.Show.HelperPanel do
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
      column size: 10 do
        label(content: "GPG email: #{panel.config.gpg_email}")
      end

      column size: 10 do
        label(content: "something else")
      end
    end
  end

  defstruct [:config, :help]

  def default(config) do
    %HelperPanel{config: config, help: %{}}
  end

  def update_help(%HelperPanel{} = panel, help_map) do
    %HelperPanel{panel | help: help_map}
  end
end
