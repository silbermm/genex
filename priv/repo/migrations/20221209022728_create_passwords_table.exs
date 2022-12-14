defmodule Genex.Repo.Migrations.CreatePasswordsTable do
  use Ecto.Migration

  def change do
    create table(:passwords, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account, :string
      add :username, :string
      add :encrypted_password, :text
      add :deleted_at, :utc_datetime
      timestamps()
    end

    create index(:passwords, [:account, :username]) 
  end
end
