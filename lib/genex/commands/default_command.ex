defmodule Genex.Commands.DefaultCommand do
  @moduledoc false

  use Prompt.Command

  require Logger

  @impl true
  def process(opts) do
    generated = Diceware.generate(count: opts.length)

    generated
    |> maybe_show_choices(opts)
  end

  defp maybe_show_choices(passphrase, %{save: true} = opts) do
    with :accept <- choice(Diceware.with_colors(passphrase), accept: "a", regenerate: "r"),
         acct <- get_account_name("What account?"),
         username <- get_username("What username?") do

      psswd = Genex.Passwords.Password.new(acct, username)
      Genex.Passwords.save(psswd, passphrase)
      :ok
    else
      :regenerate ->
        _ = Prompt.Position.clear_lines(1)
        process(opts)

      _ ->
        display("Something when wrong, try again", error: true)
    end
  end

  defp maybe_show_choices(passphrase, _), do: display(Diceware.with_colors(passphrase))

  defp get_account_name(question) do
    answer = text(question, trim: true, color: :green, min: 3)

    case answer do
      :error ->
        display("Enter an account name longer that 3 charactors", color: :red)
        get_account_name(question)

      :error_min ->
        display("Enter an account name longer than 3 charactors", color: :red)
        get_account_name(question)

      account_name ->
        account_name
    end
  end

  defp get_username(question) do
    answer = text(question, trim: true, color: :green, min: 3)

    case answer do
      :error ->
        display("Enter a username longer that 3 charactors", color: :red)
        get_account_name(question)

      :error_min ->
        display("Enter a uasername longer than 3 charactors", color: :red)
        get_account_name(question)

      username ->
        username
    end
  end
end
