defmodule Genex.Repo.Migrations.AddSettingsColumns do
  use Ecto.Migration

  def change do
    alter table(:settings) do
      add :remote, :string
      add :gpg_email, :string
      add :password_length, :integer
    end
  end
end
