defmodule Krptkn.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Queue for the URLs
      {Krptkn.UrlQueue, "https://stallman.org"},

      # Start the producers
      Supervisor.child_spec({Krptkn.Spider, :p1}, id: :p1),
      Supervisor.child_spec({Krptkn.Spider, :p2}, id: :p2),

      # Start the consumers
      Supervisor.child_spec({Krptkn.Scholar, [:p1, :p2]}, id: :c1),
      Supervisor.child_spec({Krptkn.Scholar, [:p1, :p2]}, id: :c2),
      Supervisor.child_spec({Krptkn.Scholar, [:p1, :p2]}, id: :c3),
    ]

    HTTPoison.start()

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
