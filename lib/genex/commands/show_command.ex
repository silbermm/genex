defmodule Genex.Commands.ShowCommand do
  @moduledoc """

  By default gets all the saved passwords from 
  the data store and displays them (passphrases hidden)
  on the screen.

  If you know the account name, use the --for option.

  OPTIONS
  -------
    --for <account> show password for the specified account
    --help          show this help

  """

  use Prompt.Command

  @impl true
  def process(%{help: true}), do: help()

  def process(%{for: account}) when account != "" do
    case Genex.Passwords.find_by_account(account) do
      {:ok, data} ->
        show_password(data)

      {:error, _reason} ->
        []
    end
  end

  def process(_args) do
    # by default show a table of accounts/usernames
    # Ratatouille.Runtime.Supervisor.start_link(runtime: [app: Genex.Commands.ShowCommandAdvanced], config: config)
    Ratatouille.run(Genex.Commands.ShowCommandAdvanced)
  end

  defp show_password([]), do: display("account not found", color: :yellow)

  defp show_password([password]) do
    case Genex.Passwords.decrypt(password) do
      {:ok, pswd} ->
        display(Diceware.with_colors(pswd), mask_line: true)

      {:error, err} ->
        display("Unable to decrypt password: #{inspect(err)}")
    end
  end

  defp show_password([_ | _] = _passwords) do
    # multiple passwords for that account 
    :ok
  end
end
