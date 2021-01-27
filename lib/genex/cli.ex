defmodule Genex.CLI do
  @moduledoc """
  Password Manager that uses RSA to encrypt.

    --help, -h          Prints help message
    --generate, -g      Generate a password and save it
    --list, -l          List all accounts for which passwords exist
    --find account, -f  Find a previously saved password based on a certain account
    --create-certs, -c  Create Public and Private Key Certificates
    --add-remote        Add a remote filesystem to share passwords - supports local filesystem or ssh
    --list-remotes      List configured remotes and their status
    --delete-remote     Delete an already configured remote
    --add-peer          Add a trusted peer from a configured remote
  """
  import Prompt
  alias Genex.Data.Credentials
  alias Genex.Remote

  @system Application.compile_env(:genex, :system_module, System)
  @genex_core Application.compile_env(:genex, :genex_core_module, Genex)

  @spec main(list) :: 0 | 1
  def main(opts) do
    opts
    |> parse_args()
    |> process()
  end

  defp process(:help) do
    _ = display(@moduledoc)
    0
  end

  defp process(:generate) do
    passphrase = Genex.generate_password()
    display(Diceware.with_colors(passphrase))

    "Save this password?"
    |> confirm()
    |> handle_save(passphrase)
  end

  defp process(:create_certs) do
    display(
      [
        "",
        "Your private key will be protected by a password.",
        "Be sure to remember this one very important password",
        "If lost, all of your Genex data will be lost.\n"
      ],
      color: IO.ANSI.green()
    )

    password = password("Enter a password")
    create_certs(password)
  end

  defp process({:find, acc}), do: search_for(acc, nil)

  defp process(:list) do
    accounts = Genex.list_accounts()
    display(accounts, color: IO.ANSI.green())
    0
  end

  defp process(:add_remote) do
    res =
      select(
        "Choose a protocol",
        ["file://", "ssh://"]
      )

    case res do
      "file://" ->
        display(
          [
            "",
            "Enter the absolute path to the folder you want to use",
            "i.e /home/user/mnt/passwords\n"
          ],
          color: IO.ANSI.green()
        )

      "ssh://" ->
        display("Enter the path as user@host:/path", color: IO.ANSI.green())
    end

    path = text("Enter the path")

    display("Enter a name to use when referencing the remote\n",
      color: IO.ANSI.green()
    )

    name = text("Enter a name")

    case Remote.add(name, res <> path) do
      :ok ->
        0

      _ ->
        # TODO: better error
        display("Something went wrong.", IO.ANSI.red())
        1
    end
  end

  defp process(:list_remotes) do
    case Remote.list_remotes() do
      [] -> display("No remotes configured")
      remotes -> display(format_remotes(remotes))
    end
  end

  defp format_remotes(remotes) do
    Enum.map(remotes, fn r ->
      # TODO: Find a better way to add formatting 
      IO.ANSI.bright() <> "  * #{r.name}" <> IO.ANSI.normal() <> " " <> r.path
    end)
  end

  defp process({:delete_remote, remote}) do
    Genex.Remote.delete(remote)
  end

  defp process(:add_peer) do
    available_remotes = Remote.list_remotes()
    # TODO: if only 1 remote, don't ask
    # TODO: if no remotes, do something else
    res = select("Which remote?", Enum.map(available_remotes, & &1.name))

    # get peers from remote
    peers = Remote.list_remote_peers(res)
    # TODO filter out already added local peers

    peer_res = select("Which peer?", Enum.map(peers, &"HOSTNAME: #{&1.host} - OS: #{&1.os}"))
  end

  defp create_certs(password, overwrite \\ false) do
    case Genex.Encryption.OpenSSL.create_certs(password, overwrite) do
      {:error, :ekeyexists} ->
        display("Keys already exist!\n", color: IO.ANSI.red())

        answer =
          confirm("Do you want to overwrite existing keys?",
            default_answer: :no
          )

        if answer == :yes do
          create_certs(password, true)
        else
          2
        end

      :ok ->
        display("Keys created successfully", position: :left)
        0

      {:error, err} ->
        display("something went wrong #{inspect(err)}")
        1
    end

    0
  end

  defp search_for(acc, password) do
    case @genex_core.find_credentials(acc, password) do
      {:error, :password} ->
        password = password("Enter private key password")
        search_for(acc, password)

      res ->
        count = Enum.count(res)

        cond do
          count == 0 ->
            display("Unable to find a password with that account name", error: true)
            0

          count == 1 ->
            creds = res |> List.first()

            creds.passphrase
            |> Diceware.with_colors()
            |> display()

            0

          count > 1 ->
            result =
              select(
                "Multiple entries saved for #{acc}. Choose one",
                Enum.map(res, & &1.username)
              )

            handle_find_password_with_username(res, result)
        end
    end
  end

  defp parse_args(opts) do
    cmd_opts =
      OptionParser.parse(opts,
        switches: [
          help: :boolean,
          generate: :boolean,
          find: :string,
          create_certs: :boolean,
          list: :boolean,
          add_remote: :boolean,
          list_remotes: :boolean,
          delete_remote: :string,
          add_peer: :boolean
        ],
        aliases: [h: :help, g: :generate, f: :find, c: :create_certs, l: :list]
      )

    case cmd_opts do
      {[help: true], _, _} ->
        :help

      {[generate: true], _, _} ->
        :generate

      {[find: acc], _, _} ->
        {:find, acc}

      {[create_certs: true], _, _} ->
        :create_certs

      {[list: true], _, _} ->
        :list

      {[add_remote: true], _, _} ->
        :add_remote

      {[list_remotes: true], _, _} ->
        :list_remotes

      {[delete_remote: remote], _, _} ->
        {:delete_remote, remote}

      {[add_peer: true], _, _} ->
        :add_peer

      _ ->
        :help
    end
  end

  defp handle_find_password_with_username(credentials, username) do
    credentials
    |> Enum.find(fn x -> x.username == username end)
    |> case do
      nil ->
        display("error ", error: true)
        1

      res ->
        res.passphrase
        |> Diceware.with_colors()
        |> display()

        0
    end
  end

  defp handle_save(answer, password) do
    case answer do
      :no ->
        confirm("Generate a different password")
        0

      :yes ->
        account_name = text("Enter an account name that this password belongs to")
        username = text("Enter a username for this account/password")

        account_name
        |> Credentials.new(username, password)
        |> save_creds

      :error ->
        display("Error", error: true)
        1
    end
  end

  @spec save_creds(Credentials.t()) :: no_return()
  defp save_creds(credentials) do
    case Genex.save_credentials(credentials) do
      :ok ->
        display("Account saved")
        0

      {:error, _reason} ->
        display("Something went wrong trying to save your password, please try again")
        1
    end
  end
end
