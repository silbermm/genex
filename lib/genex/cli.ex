defmodule Genex.CLI do
  @moduledoc """

  Passphrase generator and decentralized passphrase manager

    generate            Generate a password and save it
    list                List all accounts that have saved passwords
    find <account_name> find, view and manipulate passwords
    certs               Generate public and private key certificates
    remote              Add, list and delete trusted remotes
    push                Push local passphrases to a trusted remote
    pull                Pull remote passphrases to local store
    peers               View and manage peers

    --help, -h          Prints help message
    --version, -v       Prints the version

  """
  use Prompt, otp_app: :genex

  @doc "Entry Point into the app"
  @spec main(list) :: 0 | 1
  def main(argv) do
    commands = [
      {"generate", Genex.CLI.GenerateCommand},
      {"list", Genex.CLI.ListAccountsCommand},
      {"find", Genex.CLI.FindCommand},
      {"certs", Genex.CLI.CertificatesCommand},
      {"remote", Genex.CLI.RemoteCommand},
      {"push", Genex.CLI.PushCommand},
      {"pull", Genex.CLI.PullCommand},
      {"peers", Genex.CLI.PeerCommand}
    ]

    process(argv, commands)
  end
end
