defmodule Genex.Configuration do
  @moduledoc """
  Get and set settings
  """

  alias Genex.Store
  alias Genex.Store.Settings

  @doc "Get settings for a specific profile - defaults to the default profile"
  @spec get(String.t()) :: Settings.t() | nil
  def get(profile \\ "default") do
    Store.for(:settings).find_by(:profile, profile)
    |> only_latest()
    |> drop_deleted()
  end

  @spec is_valid?(Settings.t()) :: boolean
  def is_valid?(settings), do: Settings.is_valid?(settings)

  @doc "Create a new settings entry"
  @spec create(map()) :: {:ok, Settings.t()} | {:error, any()}
  def create(data) do
    profile = Map.get(data, :profile, "default")

    settings =
      profile
      |> Settings.new()
      |> Settings.set_gpg(Map.get(data, :gpg_email))
      |> Settings.set_password_length(Map.get(data, :password_length))

    Store.for(:settings).create(settings)
  end

  defp group_by_profile(settings), do: Enum.group_by(settings, & &1.profile)

  defp only_latest(settings) do
    settings
    |> Enum.sort_by(& &1.timestamp, {:asc, DateTime})
    |> List.last()
  end

  defp drop_deleted(%{action: :delete}), do: nil
  defp drop_deleted(settings), do: settings
end
