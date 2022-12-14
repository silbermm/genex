defmodule Genex.Settings do
  @moduledoc """
  Get and set settings
  """

  alias Ecto.Changeset
  alias Genex.Repo
  alias __MODULE__.Setting

  @doc "Get settings for a specific profile - defaults to the default profile"
  @spec get(String.t()) :: Setting.t() | nil
  def get(profile \\ "default") do
    Repo.get_by(Setting, profile: profile)
  end

  @doc "Create a new settings entry"
  @spec create(map()) :: {:ok, Setting.t()} | {:error, Changeset.t()}
  def create(data) do
    %Setting{}
    |> Setting.changeset(data)
    |> Repo.insert()
  end

  @doc "Generic update function for Settings"
  @spec update(Setting.t(), map()) :: {:ok, Setting.t()} | {:error, Changeset.t()}
  def update(setting, data) do
    setting
    |> Setting.changeset(data)
    |> Repo.update()
  end

  @doc """
  Create or update the api_key

  Defaults to using the default settings profile,
  pass the `profile` option to use a different profile
  """
  @spec upsert_api_key(String.t(), keyword()) :: {:ok, Setting.t()} | {:error, Changeset.t()}
  def(upsert_api_key(api_key, opts \\ [])) do
    profile = Keyword.get(opts, :profile, "default")
    settings = get(profile) || %Setting{}

    settings = Setting.changeset(settings, %{api_key: api_key, profile: profile})
    Repo.insert_or_update(settings)
  end
end
