defmodule Krptkn.Repo.Migrations.CreateUrls do
  use Ecto.Migration

  def change do
    create table(:urls) do
      add :session, :string
      add :url, :string
      add :type, :string

      timestamps()
    end

    create unique_index(:urls, [:url])
  end
end
