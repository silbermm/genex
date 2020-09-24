defmodule Genex.Environment do
  @moduledoc """
  Deals with GenexCore specific environment, such as loading specific
  GenexCore environment variables or providing defaults.
  """

  @doc """
  First looks for the environment variable and returns the value.
  If the environment variable is not found, look for the supplied genex
  config value. If that is not defined, return the default.
  """
  @spec load_variable(String.t(), atom(), binary() | nil) :: binary()
  def load_variable(env_variable_name, genex_config_name, default \\ nil) do
    case System.get_env(env_variable_name) do
      nil -> Application.get_env(:genex, genex_config_name, default)
      val -> val
    end
  end
end
