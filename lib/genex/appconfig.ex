defmodule Genex.AppConfig do
  @moduledoc """
  Read from and write to the users configuration file
  """

  alias __MODULE__

  @config_filename "config.toml"

  @type t :: %__MODULE__{
          gpg_email: String.t() | nil,
          password_length: number()
        }

  defstruct [:gpg_email, :password_length]

  defp homedir(), do: Application.fetch_env!(:genex, :homedir)

  defp config_file_path(), do: Path.join(homedir(), @config_filename)

  @doc "Read from the config file"
  @spec read() :: {:ok, t()} | {:error, any()}
  def read() do
    config_file_path()
    |> Toml.decode_file()
    |> case do
      {:ok, toml} ->
        decode(toml)

      e ->
        e
    end
  end

  @doc """
  Write the config to disk
  """
  @spec write(t()) :: :ok | {:error, term()}
  def write(config) do
    # build a toml representation of the config
    toml = ~s"""
    [gpg]
      email = "#{config.gpg_email}"
    """

    File.write(config_file_path(), toml)
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

  defp decode(toml) do
    {:ok,
     %AppConfig{
       gpg_email: get_in(toml, ["gpg", "email"]),
       password_length: get_password_length(toml)
     }}
  end

  defp get_password_length(toml) do
    case get_in(toml, ["defaults", "password_length"]) do
      nil -> 8
      num -> num
    end
  end
end
