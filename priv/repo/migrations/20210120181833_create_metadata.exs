defmodule Krptkn.Repo.Migrations.CreateMetadata do
  use Ecto.Migration

  def change do
    create table(:metadata) do
      add :session, :string
      add :url, :string
      add :type, :string
      add :metadata, :map

      timestamps()
    end

  end
end
