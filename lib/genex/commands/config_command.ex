defmodule Genex.Commands.ConfigCommand do
  @moduledoc """

  Reads, displays and validates application config.

  The config file is located by defaul at:

    $HOME/.genex/config.toml


  OPTIONS
  -------

    --help                    show this help
  """

  use Prompt.Command

  alias Genex.AppConfig

  @impl true
  def process(%{help: true}), do: help()

  def process(_args) do
    case AppConfig.read() do
      {:ok, config} ->
        display(" 🟢 Config is valid", color: :green)

        headers = ["Property", "Value"]

        gpg = ["GPG Email", Map.get(config.gpg, "email")]
        password = ["Password Length", to_string(Map.get(config.password, "length"))]
        remote = ["Remote URL", to_string(Map.get(config.remote, "url"))]

        table([headers, gpg, password, remote], header: true)

      {:error, reason} ->
        IO.inspect(reason)
        display(" 🔴 Config is invalid", color: :red)
    end
  end
end
