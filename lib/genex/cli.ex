defmodule Genex.CLI do
  @moduledoc """

  Passphrase generator and decentralized passphrase manager

    generate            Generate a password and save it
    list                List all accounts that have saved passwords
    show <account_name> Show password for account
    certs               Generate public and private key certificates
    remote              Add, list and delete trusted remotes
    push                Push local passphrases to a trusted remote
    pull                Pull remote passphrases to local store
    peers               View and manage peers

    --help, -h          Prints help message
    --version, -v       Prints the version

  """
  import Prompt

  @spec main(list) :: 0 | 1
  def main(argv) do
    argv
    |> parse_argv()
    |> process()
  end

  defp process(:ok), do: 0
  defp process({:error, _}), do: 1

  defp process(:help) do
    _ = display(@moduledoc)
    0
  end

  defp process(:version) do
    {:ok, vsn} = :application.get_key(:genex, :vsn)
    _ = display("genex - #{List.to_string(vsn)}")
    0
  end

  defp parse_argv(argv) do
    argv
    |> OptionParser.parse_head(
      strict: [help: :boolean, version: :boolean],
      aliases: [h: :help, v: :version]
    )
    |> parse_opts()
  end

  defp parse_opts({[help: true], _, _}), do: :help
  defp parse_opts({[version: true], _, _}), do: :version

  defp parse_opts({[], ["generate" | rest], _invalid}), do: Genex.CLI.Generate.init(rest)
  defp parse_opts({[], ["list" | rest], _invalid}), do: Genex.CLI.ListAccounts.init(rest)
  defp parse_opts({[], ["show" | rest], _invalid}), do: Genex.CLI.Show.init(rest)
  defp parse_opts({[], ["certs" | rest], _invalid}), do: Genex.CLI.Certificates.init(rest)
  defp parse_opts({[], ["remote" | rest], _invalid}), do: Genex.CLI.Remote.init(rest)
  defp parse_opts({[], ["push" | rest], _invalid}), do: Genex.CLI.PushCommand.init(rest)
  defp parse_opts({[], ["pull" | rest], _invalid}), do: Genex.CLI.PullCommand.init(rest)
  defp parse_opts({[], ["peers" | rest], _invalid}), do: Genex.CLI.PeerCommand.init(rest)

  defp parse_opts(_), do: :help
end
