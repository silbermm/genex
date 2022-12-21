defmodule Genex.CLI.Commands.ConfigCommand do
  @moduledoc """
  Create and validate configuration settings  

  OPTIONS
  -------
    --profile show settings for a specific profile (defaults to the default profile)
    --guided  guided application configuration
    --help    show this help
  """

  use Prompt.Command
  alias Genex.Settings

  @impl true
  def process(%{help: true}), do: help()

  def process(%{guided: true} = args) do
    display("Guided Configuration Setup", color: :magenta)
    profile = get_profile_name(args)

    current_settings = Genex.Settings.get(profile) || %Genex.Settings.Setting{}

    params =
      %{profile: profile}
      |> get_gpg_email(current_settings)
      |> get_default_password_length(current_settings)
      |> get_remote_url(current_settings)

    case Settings.upsert_settings(current_settings, params) do
      {:ok, _set} ->
        display("Great, settings saved!", color: :green)

      {:error, changeset} ->
        # @TODO: better UX for errors
        display("Fix the errors, #{inspect(changeset.errors)}")
    end
  end

  def process(args) do
    profile = profile_arg(args)
    settings = Settings.get(profile)

    dbg(settings)

    if Settings.is_valid?(settings) do
      display(" 🟢 Config is valid", color: :green)
      headers = ["Property", "Value"]

      gpg = ["GPG Email", settings.gpg_email]
      password = ["Password Length", to_string(settings.password_length)]
      remote = ["Remote URL", to_string(settings.remote)]

      table([headers, gpg, password, remote], header: true)
    else
      display(" 🔴 Config is invalid", color: :red)
      display("Please run genex config --guided", color: :yellow)
    end
  end

  defp profile_arg(%{profile: ""}), do: "default"
  defp profile_arg(%{profile: profile}), do: profile

  defp get_profile_name(%{profile: ""}) do
    case Prompt.text("Profile name (press enter for the default)", color: :green, trim: true) do
      "" -> "default"
      other -> other
    end
  end

  defp get_profile_name(%{profile: profile}), do: profile

  defp get_gpg_email(params, current_settings) do
    # @TODO: list known GPG keys on the system and offer a selection
    display(
      "\nGenex works by using a GPG key and requires the email you used to configure your GPG key",
      color: :cyan
    )

    user_entered = prompt("Email", :gpg_email, current_settings)
    Settings.build_params_for(:gpg_email, user_entered, params)
  end

  defp get_default_password_length(params, current_settings) do
    user_entered = prompt("Default password length", :password_length, current_settings)
    Settings.build_params_for(:password_length, user_entered, params)
  end

  defp get_remote_url(params, current_settings) do
    case Prompt.confirm("Would you like to setup remote syncing?", color: :green) do
      :yes ->
        user_entered = prompt("Remote Server", :remote, current_settings)
        Settings.build_params_for(:remote, user_entered, params)

      :no ->
        params
    end
  end

  defp prompt(string, key, current_settings) do
    case Map.get(current_settings, key) do
      val when val == "" or is_nil(val) ->
        Prompt.text(string, color: :green, trim: true)

      val ->
        Prompt.text("#{string} (currently #{val})", color: :green, trim: true)
    end
  end
end
