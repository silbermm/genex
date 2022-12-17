defmodule Genex.Settings.Setting do
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "settings" do
    field :profile, :string, default: "default"
    field :remote, :string
    field :api_key, :string
    field :gpg_email, :string
    field :password_length, :integer, default: 8

    timestamps()
  end

  @all [:profile, :api_key, :remote, :gpg_email, :password_length]
  @required [:profile, :gpg_email]

  def changeset(data, params) do
    data
    |> cast(params, @all)
    |> validate_required(@required)
    |> unique_constraint(:profile)
  end
end
