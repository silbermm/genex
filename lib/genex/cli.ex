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

  @halter_module Application.compile_env!(:genex, :halter)

  command :show, ShowCommand do
    arg(:help, :boolean)
    arg(:for, :string)
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

  @impl true
  def handle_exit_value(_) do
    @halter_module.halt()
  end
end
