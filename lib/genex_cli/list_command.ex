defmodule GenexCLI.ListCommand do
  @moduledoc """
  List available password keys

  OPTIONS
  -------
    --profile,-p {profile_name}  generate and save the password for 
                                 a specific profile

    --help                       show this help
  """

  use Prompt.Command
  alias Genex.Configuration
  alias Genex.Passwords

  @impl true
  def process(%{help: true}), do: help()

  def process(%{profile: profile} = args) do
    config = Configuration.get(profile)

    if Configuration.is_valid?(config) do
      passwords = Passwords.all(profile: profile)

      case passwords do
        [] ->
          display("No passphrases saved for profile \"#{profile}\"")

        _ ->
          passwords
          |> Enum.map(& &1.key)
          |> Enum.chunk_every(4)
          |> table(border: :none, color: :blue)
      end

      0
    else
      display("Configuration is required before using the application.", color: :red)
      display("Please run \"genex config --guided\" first", color: :green)
      1
    end
  end
end
