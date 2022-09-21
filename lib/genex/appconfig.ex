defmodule Genex.AppConfig do
  @moduledoc """
  Read and validate the users configuration file
  """

  alias Vapor.Provider.File

  @config_filename "config.toml"

  @config_bindings [
    {:gpg, "gpg", required: true},
    {:password, "password", default: 8}
  ]

  defp homedir(), do: Application.fetch_env!(:genex, :homedir)
  defp config_file_path(), do: Path.join(homedir(), @config_filename)

  @doc "Read from the config file"
  @spec read() :: {:ok, map()} | {:error, any()}
  def read() do
    providers = [
      %File{path: config_file_path(), bindings: @config_bindings}
    ]

    Vapor.load(providers)
  end
end
