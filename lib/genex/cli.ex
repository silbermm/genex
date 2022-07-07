defmodule Genex.CLI do
  @moduledoc """

  genex - generate unique, memorizable passphrases

    SUB-COMMANDS
    ------------
      config check if the app is configured correctly
      show   show all passwords


    OPTIONS
    -------
      --length, -l   how many words to use in the passphrase
                     defaults to 6
      --save, -s     have the option to save
                     the generated passphrase
      --version, -v  prints the version of genex
      --help, -h     prints help
  """

  use Prompt.Router, otp_app: :genex

  require Logger

  alias Genex.Commands.ConfigCommand
  alias Genex.Commands.DefaultCommand
  alias Genex.Commands.ShowCommand

  command :show, ShowCommand do
    arg(:help, :boolean)
  end

  command :config, ConfigCommand do
    arg(:help, :boolean)
    arg(:set, :string)
  end

  command "", DefaultCommand do
    arg(:help, :boolean)
    arg(:length, :integer, default: 6)
    arg(:save, :boolean)
  end

  @spec handle_exit_value(any) :: no_return()
  defp handle_exit_value(:ok), do: handle_exit_value(0)

  defp handle_exit_value({:error, _reason}) do
    # TODO: better handle non :ok exit
    handle_exit_value(1)
  end

  defp handle_exit_value(val) when is_integer(val) and val >= 0 do
    Logger.debug("Exit Code: #{val}")
    # Prevent exiting if running from an iex console.
    unless Code.ensure_loaded?(IEx) and IEx.started?() do
      System.halt(val)
    end
  end

  defp handle_exit_value(anything_else) do
    Logger.debug("Exit Value: #{inspect(anything_else)}")
    handle_exit_value(2)
  end
end
