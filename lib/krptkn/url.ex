defmodule Krptkn.Url do
  use Ecto.Schema
  import Ecto.Changeset

  schema "urls" do
    field :session, :string
    field :type, :string
    field :url, :string

    timestamps()
  end

  @doc false
  def changeset(url, attrs) do
    url
    |> cast(attrs, [:session, :url, :type])
    |> validate_required([:session, :url, :type])
    |> unique_constraint(:url)
  end
end
