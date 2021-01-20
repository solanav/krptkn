defmodule Krptkn.Metadata do
  use Ecto.Schema
  import Ecto.Changeset

  schema "metadata" do
    field :metadata, :map
    field :session, :string
    field :type, :string
    field :url, :string

    timestamps()
  end

  @doc false
  def changeset(metadata, attrs) do
    metadata
    |> cast(attrs, [:session, :url, :type, :metadata])
    |> validate_required([:session, :url, :type, :metadata])
  end
end
