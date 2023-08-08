defmodule GenexCLI.GenerateCommand do
  @moduledoc """
  Generate a new passphrase and optionally save it

  OPTIONS
  -------
    --profile,-p {profile_name}  generate and save the password for 
                                 a specific profile

    --key,-k {key_name}          save the password under a specific key
                                 e.g aws/username
                                   Genex will prompt for this if it's not
                                   passed in explicitly  

    --yes,-y                     save the first generated password
                                   should be used in conjunction
                                   with --key

    --help                       show this help


  EXAMPLES
  --------
  Generate a new passphrase for a profile called "work"
  #{IO.ANSI.bright()}genex generate --profile work#{IO.ANSI.normal()}

  Generate a new passphrase and automatically save it w/o prompts
  #{IO.ANSI.bright()}genex generate --key myservice/myusername -y#{IO.ANSI.normal()}
  """

  use Prompt.Command
  alias Genex.Configuration
  alias Genex.Passwords

  @impl true
  def process(%{help: true}), do: help()

  def process(%{profile: profile} = args) do
    config = Configuration.get(profile)

    if Configuration.is_valid?(config) do
      pass = Passwords.generate(config.password_length)
      generate_passphrase(pass, config, args)
    else
      display("Configuration is required before using the application.", color: :red)
      display("Please run \"genex config --guided\" first", color: :green)
      1
    end
  end

  defp generate_passphrase(pass, config, args) do
    display("#{Diceware.with_colors(pass)}")

    args.yes
    |> save_edit_or_regenerate()
    |> case do
      :save ->
        display(IO.ANSI.clear())
        display("Screen cleared to preserve password privacy", color: :yellow)

        # if they passed in a key, use that, otherwise, prompt them for a key
        key = if args.key != "", do: args.key, else: ask_for_key()

        case Passwords.save(key, pass, config) do
          {:ok, _passphrase} ->
            _ = Clipboard.copy(pass.phrase)
            display("Passphrase for #{key} saved and copied", color: :magenta)
            0

          {:error, _reason} ->
            display("Unable to save passphrase", color: :red)
            1
        end

      :edit ->
        passphrase = edit_passphrase(pass)
        generate_passphrase(passphrase, config, args)

      :cancel ->
        0

      :regenerate ->
        Prompt.Position.clear_lines(2)
        pass = Passwords.generate(config.password_length)
        generate_passphrase(pass, config, args)
    end
  end

  defp save_edit_or_regenerate(true), do: :save

  defp save_edit_or_regenerate(_) do
    choice(
      "Do you want to save this password? (yes/no/edit/regenerate)",
      [save: "y", cancel: "n", edit: "e", regenerate: "r"],
      color: :green
    )
  end

  defp ask_for_key() do
    display(
      """

      Genex requires that passphrases are saved under unique keys.
      Typically, it's best to use a key that describes the service
      and the username separated with "/", like:

      "aws/my_username@email.com".
      """,
      color: :cyan
    )

    _ask_for_key("")
  end

  defp _ask_for_key(value) when value != "", do: value

  defp _ask_for_key(""),
    do: _ask_for_key(text("Enter a key for this passphrase", trim: true, color: :green))

  defp edit_passphrase(passphrase) do
    old_value = select("Which part of the passphrase do you want to change?", passphrase.words)
    new_value = text(~s[Editing "#{old_value}"], trim: true)

    new_words =
      passphrase.words
      |> Enum.map(fn
        ^old_value -> new_value
        keep -> keep
      end)
      |> Enum.reject(&(&1 == ""))

    Diceware.Passphrase.new(new_words)
  end
end
