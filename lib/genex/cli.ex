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
    --push-remotes      Push passwords to peers for a remote
    --pull-remotes      Pull passwords from peers for a remote
    --sync-peers        Pull in new peers from a remote
    --list-peers        List trusted peers and which remote they belong to
  """
  import Prompt
  alias Genex.Data.Credentials
  alias Genex.{Passwords, Remote}

  @spec main(list) :: 0 | 1
  def main(opts) do
    opts
    |> build_opts()
    |> parse_opts()
    |> process()
  end

  defp process(:help) do
    _ = display(@moduledoc)
    0
  end

  defp process(:generate) do
    passphrase = Passwords.generate()
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
    accounts = Passwords.list_accounts()
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
      {:ok, remote} ->
        add_peers(remote)
        0

      _err ->
        display("Something went wrong.", color: IO.ANSI.red())
        1
    end
  end

  defp process(:list_remotes) do
    case Remote.list_remotes() do
      [] ->
        display("No remotes configured")
        0

      remotes ->
        display(format_remotes(remotes))
        0
    end
  end

  defp process(:push_remotes) do
    remotes = Remote.list_remotes()

    res =
      select(
        "Choose a remote to push to",
        Enum.map(remotes, fn r ->
          {IO.ANSI.bright() <> "  * #{r.name}" <> IO.ANSI.normal() <> " " <> r.path, r}
        end)
      )

    password = password("Private key password")
    Remote.push(res, password)
    0
  end

  defp process(:pull_remotes) do
    # pull remotes passwords into our db password
    remotes = Remote.list_remotes()

    res =
      select(
        "Choose a remote to pull from",
        Enum.map(remotes, fn r ->
          {IO.ANSI.bright() <> "  * #{r.name}" <> IO.ANSI.normal() <> " " <> r.path, r}
        end)
      )

    password = password("Private key password")
    Remote.pull(res, password)
    0
  end

  defp process({:delete_remote, remote}), do: Remote.delete(remote)

  defp process(:list_peers) do
    peers = Remote.list_local_peers()
    peers = Enum.map(peers, &"#{&1.id} - #{&1.host} - #{&1.remote.name}")
    display(peers, color: IO.ANSI.green())
    0
  end

  defp process(:sync_peers) do
    remotes = Remote.list_remotes()

    res =
      select(
        "Choose a remote to sync with",
        Enum.map(remotes, fn r ->
          {IO.ANSI.bright() <> "  * #{r.name}" <> IO.ANSI.normal() <> " " <> r.path, r}
        end)
      )

    case Remote.add(res.name, res.path) do
      {:ok, remote} ->
        add_peers(remote)
        0

      _err ->
        display("Something went wrong.", color: IO.ANSI.red())
        1
    end
  end

  defp format_remotes(remotes) do
    Enum.map(remotes, fn r ->
      IO.ANSI.bright() <> "  * #{r.name}" <> IO.ANSI.normal() <> " " <> r.path
    end)
  end

  defp add_peers(remote) do
    # add peers from remote just added
    remote_peers = Remote.list_remote_peers(remote.name)

    for peer <- remote_peers do
      Remote.add_peer(peer, remote)
    end
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
    case Passwords.find(acc, password) do
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

  defp build_opts(opts) do
    OptionParser.parse(opts,
      strict: [
        help: :boolean,
        generate: :boolean,
        find: :string,
        create_certs: :boolean,
        list: :boolean,
        add_remote: :boolean,
        list_remotes: :boolean,
        push_remotes: :boolean,
        pull_remotes: :boolean,
        delete_remote: :string,
        list_peers: :boolean,
        sync_peers: :boolean
      ],
      aliases: [h: :help, g: :generate, f: :find, c: :create_certs, l: :list]
    )
  end

  defp parse_opts({[help: true], _, _}), do: :help
  defp parse_opts({[generate: true], _, _}), do: :generate
  defp parse_opts({[find: acc], _, _}), do: {:find, acc}
  defp parse_opts({[create_certs: true], _, _}), do: :create_certs
  defp parse_opts({[list: true], _, _}), do: :list
  defp parse_opts({[add_remote: true], _, _}), do: :add_remote
  defp parse_opts({[list_remotes: true], _, _}), do: :list_remotes
  defp parse_opts({[push_remotes: true], _, _}), do: :push_remotes
  defp parse_opts({[pull_remotes: true], _, _}), do: :pull_remotes
  defp parse_opts({[delete_remote: remote], _, _}), do: {:delete_remote, remote}
  defp parse_opts({[list_peers: true], _, _}), do: :list_peers
  defp parse_opts({[sync_peers: true], _, _}), do: :sync_peers
  defp parse_opts(_), do: :help

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
    case Passwords.save(credentials) do
      :ok ->
        display("Account saved")
        0

      {:error, _reason} ->
        display("Something went wrong trying to save your password, please try again")
        1
    end
  end
end
