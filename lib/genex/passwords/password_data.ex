defmodule Genex.Passwords.PasswordData do
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder, only: [:account, :username, :encrypted_password, :deleted_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "passwords" do
    field :account, :string
    field :username, :string
    field :encrypted_password, :string
    field :passphrase, :string, virtual: true
    field :deleted_at, :utc_datetime
    field :profile, :string, default: "default"

    timestamps()
  end

  @required [:account, :username, :encrypted_password, :profile]

  def changeset(data, params) do
    data
    |> cast(params, @required)
    |> validate_required(@required)
  end

  def delete_changeset(data) do
    data
    |> cast(%{deleted_at: DateTime.utc_now(), encrypted_password: nil}, [:deleted_at | @required])
    |> validate_required([:deleted_at])
  end
end
