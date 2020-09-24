defmodule Genex.CLI do
  @moduledoc """
  Password Manager that uses RSA to encrypt.

    --help          Prints help message
    --generate      Generate a password and save it
    --find account  Find a previously saved password based on a certain account
    --create-certs  Create Public and Private Key Certificates
  """

  alias Genex.CLI.Prompt

  @system Application.get_env(:genex, :system_module, System)
  @genex_core Application.get_env(:genex, :genex_core_module, Genex)

  def main(opts) do
    # set the nodename and cookie
    opts
    |> parse_args
    |> process
  end

  defp process(:help) do
    IO.write(@moduledoc)
    @system.halt(0)
  end

  defp process(:generate) do
    passphrase = @genex_core.generate_password() 
    display(passphrase)
    Prompt.prompt_to_save(passphrase, &handle_save/2)
  end

  defp process(:create_certs) do
    IO.write("create certificiates") 
  end

  defp process({:find, acc}) do
    search_for(acc, nil)
  end

  defp search_for(acc, password) do
    case @genex_core.find_credentials(acc, password) do
      {:error, :password} ->
        Prompt.prompt_for_encryption_key_password(acc, &search_for/2)

      :error ->
        IO.puts("error encountered when searching for account")

      res ->
        count = Enum.count(res)

        # TODO: Put all of this in the Prompt module
        cond do
          count == 0 ->
            IO.puts("Unable to find a password with that account name")

          count == 1 ->
            IO.puts("#{List.first(res).password}")

          count > 1 ->
            Prompt.prompt_for_specific_account(acc, res, &handle_find_password_with_username/3)
        end
    end
  end

  defp parse_args(opts) do
    cmd_opts =
      OptionParser.parse(opts,
        switches: [help: :boolean, generate: :boolean, find: :string, create_certs: :boolean],
        aliases: [h: :help, g: :generate, f: :find, c: :create_certs]
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

      _ ->
        :help
    end
  end

  defp display(passphrase) do
    passphrase
    |> Diceware.with_colors
    |> IO.puts()
  end

  defp handle_find_password_with_username(acc, credentials, username) do
    credentials
    |> Enum.find(fn x -> x.username == username end)
    |> case do
      nil ->
        IO.puts("Input didn't match any kmown username, try again")

        Prompt.prompt_for_specific_account(
          acc,
          credentials,
          &handle_find_password_with_username/3
        )

      res ->
        IO.puts("Password = #{res.password}")
    end
  end

  defp handle_save(password, answer) do
    answer
    |> String.trim()
    |> String.downcase()
    |> case do
      "n" ->
        Prompt.prompt_for_next()

      "y" ->
        password
        |> Prompt.prompt_for_account()
        |> save_creds

      "" ->
        password
        |> Prompt.prompt_for_account()
        |> save_creds

      _ ->
        IO.puts("Sorry, I didn't understand your answer...")
        Prompt.prompt_to_save(password, &handle_save/2)
    end
  end

  defp save_creds(credentials) do
    case Genex.save_credentials(credentials) do
      :ok ->
        IO.puts("Account saved")
        @system.halt(0)

      {:error, _reason} ->
        IO.puts("Something went wrong trying to save your password, please try again")
        @system.halt(2)
    end
  end
end
