defmodule Genex.AppConfig do
  @moduledoc """
  Read from and write to the users configuration file
  """


  alias Vapor.Provider.File

  @config_filename "config.toml"

  @config_bindings [{:gpg, "gpg"}, {:password_length, "password_length", default: 8}]

  @type t :: %__MODULE__{
    gpg: map(),
    password_length: number()
  }

  defstruct [:gpg, :password_length]

  defp homedir(), do: Application.fetch_env!(:genex, :homedir)
  defp config_file_path(), do: Path.join(homedir(), @config_filename)

  @doc "Read from the config file"
  @spec read() :: {:ok, map()} | {:error, any()}
  def read() do
    providers = [
      %File{path: "/home/silbermm/.genex/config.toml", bindings: @config_bindings}
    ]

    Vapor.load(providers)
  end

  @doc """
  Write the config to disk
  """
  @spec write(map()) :: :ok | {:error, term()}
  def write(config) do
    # build a toml representation of the config
    toml = ~s"""
    [gpg]
      email = "#{config.gpg_email}"
    """

    Elixir.File.write(config_file_path(), toml)
  end

  @doc """
  Determines if the key is valid
  """
  @spec valid_key?(String.t()) :: boolean()
  def valid_key?(key) do
    Genex.AppConfig.__struct__()
    |> Map.keys()
    |> Enum.reject(&(&1 == :__struct__))
    |> Enum.find(fn k -> to_string(k) == key end)
    |> case do
      nil -> false
      _ -> true
    end
  end

  def update(config, key, value) do
    Map.put(config, key, value)
  end
end
