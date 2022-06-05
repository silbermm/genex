defmodule Genex.AppConfig do
  @moduledoc """
  Read from and write to the users configuration file
  """

  @config_filename "config.toml"

  @type t :: %__MODULE__{
          gpg_email: String.t() | nil
        }

  defstruct [:gpg_email]

  defp homedir(), do: Application.fetch_env!(:genex, :homedir)

  @doc "Read from the config file"
  @spec read() :: {:ok, t()} | {:error, any()}
  def read() do
    homedir()
    |> Path.join(@config_filename)
    |> Toml.decode_file()
    |> case do
      {:ok, toml} ->
        decode(toml)

      e ->
        e
    end
  end

  defp decode(toml) do
    {:ok, %__MODULE__{gpg_email: get_in(toml, ["gpg", "email"])}}
  end
end
