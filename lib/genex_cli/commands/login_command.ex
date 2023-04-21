defmodule Genex.CLI.Commands.LoginCommand do
  @moduledoc """

  Attempts to login to the configured remote using
  the public key for the configured gpg email

  OPTIONS
  -------

    --profile a profile to use - defaults to the default
    --help    show this help
  """

  use Prompt.Command
  alias Genex.Settings
  alias Genex.Settings.Setting

  @impl true
  def process(%{help: true}), do: help()

  def process(%{profile: profile}) do
    case Settings.get(profile) do
      nil ->
        nil

      %Setting{gpg_email: email, remote: remote} ->
        login(remote, email, profile)
    end
  end

  defp login(nil, _email, _), do: display("Invalid remote configuration", color: :red)

  defp login(remote, email, profile) do
    remote
    |> get_challenge(email)
    |> decrypt_challenge()
    |> submit_challenge_response(remote, email)
    |> case do
      token when not is_nil(token) ->
        _ = Settings.upsert_api_key(token, profile: profile)
        display("Successfully logged in", color: :green)

      _ ->
        display("Unable to login", color: :red)
    end
  end

  defp get_challenge(remote, email) do
    # send a request to POST #{remote}/api/login/#{email} and get back a challenge
    case Req.put("#{remote}/api/login/#{email}") do
      {:ok, res} ->
        res.body["challenge"]

      {:error, reason} ->
        display("Unable to login #{inspect(reason)}")
        nil
    end
  end

  defp decrypt_challenge(nil), do: nil

  defp decrypt_challenge(challenge) do
    case GPG.decrypt(challenge) do
      {:ok, decrypted} ->
        decrypted

      {:error, reason} ->
        display("Unable to decrypt challenge #{inspect(reason)}")
        nil
    end
  end

  defp submit_challenge_response(nil, _remote, _email) do
    IO.inspect("INVALID DECRYPTED RESPONSE")
    nil
  end

  defp submit_challenge_response(response, remote, email) do
    case Req.post("#{remote}/api/login/#{email}", json: %{challenge_response: response}) do
      {:ok, %Req.Response{status: 200} = res} ->
        res.body["token"]

      {:ok, other} ->
        IO.inspect(other)
        display("Unable to login")
        nil

      {:error, reason} ->
        display("Unable to login #{inspect(reason)}")
        nil
    end
  end
end
