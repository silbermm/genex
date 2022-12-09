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

  @required [:account, :username, :encrytped_password]

  def changeset(schema, params) do
    schema
    |> cast(params, @required)
    |> validate_required(@required)
    |> unique_constraint([:account, :username])
  end
end
