defmodule Krptkn.Repo do
  use Ecto.Repo,
    otp_app: :krptkn,
    adapter: Ecto.Adapters.Postgres
end
