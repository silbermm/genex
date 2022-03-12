defmodule Genex.Commands.DefaultCommand do
  @moduledoc """
  Basic Help for Genex
  """

  use Prompt.Command

  @impl true
  def init(_list) do
    %{}
  end

  @impl true
  def process(_term) do
    :ok
  end

end
