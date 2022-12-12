defmodule Genex.Passwords.PasswordData do
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "passwords" do
    field :account, :string
    field :username, :string
    field :encrypted_password, :string
    field :passphrase, :string, virtual: true
    field :deleted_at, :utc_datetime

    timestamps()
  end

  @required [:account, :username, :encrypted_password]

  def changeset(data, params) do
    data
    |> cast(params, @required)
    |> validate_required(@required)
    |> unique_constraint([:account, :username])
  end

  def delete_changeset(data) do
    data
    |> cast(%{deleted_at: DateTime.utc_now(), encrypted_password: nil}, [:deleted_at | @required])
    |> validate_required([:deleted_at])
  end
end
