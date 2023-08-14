defmodule GenexCLI.GetCommand do
  @moduledoc """
  Get a passphrase from a key

  #{IO.ANSI.green()}genex get [options] {key}#{IO.ANSI.reset()}

  OPTIONS
  -------
    --profile,-p {profile_name}  generate and save the password for 
                                 a specific profile

    --copy,-c                    automatically copy the found passphrase
                                 to the clipboard

    --display,-d                 automatically display the passphrase in
                                 the terminal

    --help                       show this help

  EXAMPLES
  --------

  Copy the passphrase for the key github.com/username
  #{IO.ANSI.green()}genex get -c github.com/username#{IO.ANSI.reset()}


  Display the passphrase for the key aws/username in the work profile
  #{IO.ANSI.green()}genex get -d --profile work aws/username#{IO.ANSI.reset()}


  """

  use Prompt.Command
  alias Genex.Configuration
  alias Genex.Passwords

  def init(args) do
    # a leftover arg is required here for the key name    
    key = List.first(args.leftover, nil)
    Map.put(args, :key, key)
  end

  @impl true
  def process(%{help: true}), do: help()

  def process(%{key: nil}) do
    display("Key was not provided, please provide a key", color: :red)
    help()
  end

  def process(%{profile: profile, key: key} = args) do
    config = Configuration.get(profile)

    if Configuration.is_valid?(config) do
      # passwords = Passwords.all(profile: profile)
      password = Passwords.find_by_key(key, profile)

      case password do
        [] ->
          display("Unable to find a passphase for the key \"#{key}\" in \"#{profile}\" profile.")

        [passphrase] ->
          next = determine_next_step(args)

          case next do
            :copy ->
              {:ok, decrypted} = Passwords.decrypt(passphrase)
              _ = Clipboard.copy(decrypted.phrase)
              display("copied")
              0

            :quit ->
              0

            :display ->
              {:ok, decrypted} = Passwords.decrypt(passphrase)
              display(Diceware.with_colors(decrypted), mask_line: true)
              0
          end
      end
    else
      display("Configuration is required before using the application.", color: :red)
      display("Please run \"genex config --guided\" first", color: :green)
      1
    end
  end

  defp determine_next_step(%{copy: true}), do: :copy
  defp determine_next_step(%{display: true}), do: :display

  defp determine_next_step(_) do
    choice(
      "Would you like to (c)opy it, (d)isplay it, or (q)uit?",
      [copy: "c", display: "d", quit: "q"],
      default_answer: :copy,
      color: :green
    )
  end
end
