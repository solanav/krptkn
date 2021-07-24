defmodule Krptkn.Consumers.Db do
  @moduledoc """
  This module defines the consumer that inserts the data into a database
  """

  require Logger

  use GenStage

  defp insert_url(type, url) do
    session = Application.get_env(:krptkn, Krptkn.Application)[:session_name]

    url = %Krptkn.Url{
      session: session,
      type: type,
      url: url,
    }

    Krptkn.Repo.insert!(url)
  end

  defp insert_metadata(type, url, metadata, dangerous) do
    session = Application.get_env(:krptkn, Krptkn.Application)[:session_name]

    metadata = %Krptkn.Metadata{
      metadata: metadata,
      session: session,
      type: type,
      url: url,
      dangerous: dangerous,
    }

    Krptkn.Repo.insert!(metadata)
  end

  def start_link(_) do
    GenStage.start_link(__MODULE__, [])
  end

  def init(_) do
    {:consumer, :na, subscribe_to: [Krptkn.Distributors.Db]}
  end

  def handle_events(events, _from, state) do
    # Insert the elements into the database
    Enum.map(events, fn
      {:url, {type, url}} -> insert_url(type, url)
      {:metadata, {type, url, metadata, dangerous}} -> insert_metadata(type, url, metadata, dangerous)
      _ -> Logger.error("Unknown event in db inserter")
    end)

    {:noreply, [], state}
  end
end
