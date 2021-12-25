defmodule Genex.CLI do
  @moduledoc """

  Passphrase generator and decentralized passphrase manager

    generate            Generate a password and save it
    list                List all accounts that have saved passwords
    find <account_name> find, view and manipulate passwords

    --help, -h          Prints help message
    --version, -v       Prints the version

  """
  use Prompt, otp_app: :genex

  @doc "Entry Point into the app"
  @spec main(list) :: 0 | 1
  def main(argv) do
    process(argv,
      generate: Genex.CLI.GenerateCommand
      # list: Genex.CLI.ListAccountsCommand,
      # find: Genex.CLI.FindCommand
    )
  end
end
