defmodule GenexCLI.UpdateCommand do
  @moduledoc """
  Update an existing passphrase

  #{IO.ANSI.green()}genex update [options] {key}#{IO.ANSI.reset()}

  OPTIONS
  -------
    --profile,-p {profile_name}  generate and save the password for 
                                 a specific profile

    --help                       show this help

  EXAMPLES
  --------
  Update the passphrase for the key github.com/username
  #{IO.ANSI.green()}genex update github.com/username#{IO.ANSI.reset()}

  Update a passphrase by choosing form a list of keys
  #{IO.ANSI.green()}genex update#{IO.ANSI.reset()}
  """

  use Prompt.Command
  alias Genex.Configuration
  alias Genex.Passwords

  def init(args) do
    # a leftover arg could be here which would be the key name
    key = List.first(args.leftover, nil)
    Map.put(args, :key, key)
  end

  @impl true
  def process(%{help: true}), do: help()

  def process(%{profile: profile, key: nil}) do
    # get a list of keys for the profile
    config = Configuration.get(profile)

    if Configuration.is_valid?(config) do
      passwords = Passwords.all(profile: profile)

      case passwords do
        [] ->
          display("No passphrases saved for profile \"#{profile}\"")

        _ ->
          keys = passwords |> Enum.map(& &1.key)
          answer = Prompt.select("Which key do you want to update?", keys)
          passphrase = Enum.find(passwords, &(&1.key == answer))
          display(passphrase.key)
      end
    else
      display("Configuration is required before using the application.", color: :red)
      display("Please run \"genex config --guided\" first", color: :green)
      1
    end
  end

  def process(%{profile: profile, key: key}) do
    config = Configuration.get(profile)

    if Configuration.is_valid?(config) do
      password = Passwords.find_by_key(key, profile)

      case password do
        [] ->
          display("Unable to find a passphrase for the key \"#{key}\" in \"#{profile}\" profile.")

        [_passphrase] ->
          display("ok to update")
      end
    else
      display("Configuration is required before using the application.", color: :red)
      display("Please run \"genex config --guided\" first", color: :green)
      1
    end
  end
end
