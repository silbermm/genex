defmodule GenexCLI do
  @moduledoc """

  genex - generate unique, memorizable passphrases

    SUB-COMMANDS
    ------------
      config    configuration for Genex
      generate  generate passphrases and save them
      ls        list available passphrase keys for a profile
      get       get a passphrase given a key
      update    update a passphrase

    OPTIONS
    -------
      --version, -v  prints the version of genex
      --help, -h     prints help

    EXAMPLE USAGE
    -------------
  """
  use Prompt.Router, otp_app: :genex

  alias GenexCLI.ConfigCommand
  alias GenexCLI.DefaultCommand
  alias GenexCLI.GenerateCommand
  alias GenexCLI.GetCommand
  alias GenexCLI.ListCommand
  alias GenexCLI.UpdateCommand

  @halter_module Application.compile_env!(:genex, :halter)

  command :config, ConfigCommand do
    arg(:guided, :boolean, short: :g)
    arg(:profile, :string, short: :p, default: "default")
    arg(:help, :boolean)
  end

  command :generate, GenerateCommand do
    arg(:help, :boolean)
    arg(:profile, :string, default: "default", short: :p)
    arg(:key, :string, short: :k)
    arg(:yes, :boolean, short: :y)
  end

  command :ls, ListCommand do
    arg(:help, :boolean)
    arg(:profile, :string, default: "default", short: :p)
  end

  command :get, GetCommand do
    arg(:help, :boolean)
    arg(:profile, :string, default: "default", short: :p)
    arg(:copy, :boolean, short: :c)
    arg(:display, :boolean, short: :d)
  end

  command :update, UpdateCommand do
    arg(:help, :boolean)
    arg(:profile, :string, default: "default", short: :p)
  end

  command "", DefaultCommand do
    arg(:help, :boolean)
    arg(:profile, :string, default: "default")
    arg(:length, :integer, default: 6)
  end

  @impl true
  def handle_exit_value(exit_value) do
    @halter_module.halt(exit_value)
  end
end
