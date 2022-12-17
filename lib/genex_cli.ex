defmodule Genex.CLI do
  @moduledoc """

  genex - generate unique, memorizable passphrases

    SUB-COMMANDS
    ------------
      config check if the app is configured correctly
      login  login to a remote server to share passwords

    OPTIONS
    -------
      --version, -v  prints the version of genex
      --help, -h     prints help
  """
  use Prompt.Router, otp_app: :genex

  alias Genex.CLI.Commands.ConfigCommand
  alias Genex.CLI.Commands.LoginCommand
  alias Genex.CLI.Commands.DefaultCommand

  @halter_module Application.compile_env!(:genex, :halter)

  command :config, ConfigCommand do
    arg(:guided, :boolean)
    arg(:profile, :string, default: "default")
    arg(:help, :boolean)
  end

  command :login, LoginCommand do
    arg(:help, :boolean)
  end

  command "", DefaultCommand do
    arg(:help, :boolean)
    arg(:profile, :string, default: "default")
    arg(:length, :integer, default: 6)
  end

  @impl true
  def handle_exit_value(_) do
    @halter_module.halt()
  end
end
