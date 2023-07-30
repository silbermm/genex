defmodule GenexCLI.ConfigCommand do
  @moduledoc """
  Create and validate genex configuration settings

  OPTIONS
  -------
    --profile settings for a specific profile
    --guided  guided application configuration

    --help    show this help
  """

  use Prompt.Command
  alias Genex.Configuration
  alias Genex.Store.Settings

  @impl true
  def process(%{help: true}), do: help()

  def process(%{guided: true} = args) do
    profile = get_profile_name(args)
    display("Guided Configuration Setup for \"#{profile}\" profile", color: :magenta)

    current_settings = Configuration.get(profile) || Settings.new(profile)

    configuration =
      current_settings
      |> get_gpg_email()
      |> get_default_password_length()

    case Configuration.create(configuration) do
      {:ok, _set} ->
        args = Map.drop(args, [:guided])
        process(args)

      {:error, _reason} ->
        # @TODO: better UX for errors
        display("Fix the errors")
    end
  end

  def process(args) do
    profile = profile_arg(args)
    settings = Configuration.get(profile)

    if Settings.is_valid?(settings) do
      display(" 🟢 Config is valid", color: :green)
      headers = ["Property", "Value"]
      profile = ["Profile", profile]
      gpg = ["GPG Email", settings.gpg_email]
      password = ["Password Length", to_string(settings.password_length)]

      table([headers, profile, gpg, password], header: true)
      0
    else
      display(" 🔴 Config is invalid", color: :red)
      display("Please run genex config --guided", color: :yellow)
      1
    end
  end

  defp profile_arg(%{profile: ""}), do: "default"
  defp profile_arg(%{profile: profile}), do: profile

  defp get_profile_name(%{profile: profile}), do: profile

  defp get_gpg_email(current_settings) do
    display(
      """
      \nGenex works by using a GPG key for encryption.
      We'll try to list out the keys on your system for you to
      choose which one you'd like to use.
      """,
      color: :cyan
    )

    keys  = 
      GPG.list_keys()
      |> Enum.filter(& &1.has_secret)
      |> Enum.map(& {display_key(&1), List.first(&1.email)})

    if Enum.empty?(keys) do
      with :yes <- confirm("Unable to find any valid GPG keys, would you like to generate one now?", color: :yellow),
           email = text("Enter an email for this key", color: :green, trim: true),
           {:ok, _fprint} = GPG.generate_key(email) do

        display("\n ➡ setting gpg uid as #{email}", color: :white)
        Settings.set_gpg(current_settings, email)
      else
        _ -> current_settings
      end
    else 
      text = "Which key do you want to use"
      text = if current_settings.gpg_email == "" or is_nil(current_settings.gpg_email) do
        text <> "?"
      else
        text <> " (currently #{current_settings.gpg_email})?"
      end

      user_entered = select(text, keys, color: :green, trim: true)
      display("\n ➡ setting gpg uid as #{user_entered}", color: :white)
      Settings.set_gpg(current_settings, user_entered)
    end
  end

  defp display_key(key) do
    "#{List.first(key.email)}\n      fingerprint: #{key.fingerprint}"
  end

  defp get_default_password_length(current_settings) do
    display(
      """

      Genex builds readable passwords by using a number of random dictionary words
      put together to form very large passphrases.
      Here, you need to choose how many dictionary words Genex will use by default.
      """,
      color: :cyan
    )

    "Default password length"
    |> prompt(:password_length, current_settings)
    |> case do
      res when res == "" or res == "\n" -> current_settings.password_length
      other -> other
    end
    |> case do
      val when is_number(val) -> {val, ""}
      val when is_binary(val) -> Integer.parse(val)
    end
    |> case do
      :error ->
        display("Enter a number for the password length", color: :red)
        get_default_password_length(current_settings)
      {num, _} -> 
        display("\n ➡ setting password length to #{num}\n", color: :white)
        Settings.set_password_length(current_settings, num)
    end
  end

  defp prompt(string, key, current_settings) do
    case Map.get(current_settings, key) do
      val when val == "" or is_nil(val) ->
        text(string, color: :green, trim: true)

      val ->
        text("#{string} (currently #{val})", color: :green, trim: true)
    end
  end
end
