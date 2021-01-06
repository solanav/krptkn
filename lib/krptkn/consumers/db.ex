defmodule Krptkn.Consumers.Db do
  @moduledoc """
  This module defines the consumer that inserts the data into a database
  """

  require Logger

  use GenStage

  defp insert_url(_type, _url) do
    # session = Application.get_env(:krptkn, Krptkn.Application)[:session_name]
    # query = "INSERT INTO visited_urls (session, url, type) VALUES ($1, $2, $3)"
    # Postgrex.query!(:psql, query, [session, url, type])
  end

  defp insert_metadata(_type, _url, _metadata) do
    # session = Application.get_env(:krptkn, Krptkn.Application)[:session_name]
    # query = "INSERT INTO metadata (session, url, type, metadata) VALUES ($1, $2, $3, $4)"
    # Postgrex.query!(:psql, query, [session, url, type, metadata])
  end

  def start_link(_) do
    Krptkn.Api.register_process(__MODULE__, "", self())
    GenStage.start_link(__MODULE__, [])
  end

  def init(_) do
    {:consumer, :na, subscribe_to: [Krptkn.Distributors.Db]}
  end

  def handle_events(events, _from, state) do
    # Insert the elements into the database
    Enum.map(events, fn
      {:url, {type, url}} -> insert_url(type, url)
      {:metadata, {type, url, metadata}} -> insert_metadata(type, url, metadata)
      _ -> Logger.error("Unknown event in db inserter")
    end)

    {:noreply, [], state}
  end
end
