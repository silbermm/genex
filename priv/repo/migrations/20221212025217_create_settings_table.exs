defmodule Genex.Repo.Migrations.CreateSettingsTable do
  use Ecto.Migration

  def change do
    create table(:settings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile, :string, null: false, comment: "A unique name for the specific configuration", default: "default"
      add :api_key, :string

      timestamps()
    end

    create unique_index(:settings, [:profile])

  end
end
