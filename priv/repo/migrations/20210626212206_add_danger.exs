defmodule Krptkn.Repo.Migrations.AddDanger do
  use Ecto.Migration

  def change do
    alter table(:metadata) do
      add :dangerous, :boolean
    end
  end
end
