defmodule Genex.Repo.Migrations.AddProfileToPasswords do
  use Ecto.Migration

  def change do
    alter table(:passwords) do
      add :profile, :string, null: false, default: "default"
    end
  end
end
