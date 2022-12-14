defmodule Genex.Settings.Setting do
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "settings" do
    field :profile, :string, default: "default"
    field :api_key, :string

    timestamps()
  end

  @all [:profile, :api_key]

  def changeset(data, params) do
    data
    |> cast(params, @all)
    |> unique_constraint(:profile)
  end
end
