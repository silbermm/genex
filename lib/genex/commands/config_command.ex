defmodule Genex.Commands.ConfigCommand do
  @moduledoc """

  genex config

    --help  show this help
  """

  use Prompt.Command

  @impl true
  def process(_args) do
    IO.inspect(Genex.AppConfig.read())
    :ok
  end
end
