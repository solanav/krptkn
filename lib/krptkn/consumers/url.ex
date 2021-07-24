defmodule Krptkn.Consumers.Url do
  @moduledoc """
  This module defines the consumer that extracts URLs from the files
  that the spider module generates. After extracting the URLs, they are put
  into a global queue that the producer can pop from.
  """

  use GenStage

  def start_link(name) do
    GenStage.start_link(__MODULE__, [], name: name)
  end

  def init(_) do
    {:producer_consumer, :na, subscribe_to: [Krptkn.Distributors.Url]}
  end

  def handle_events(events, _from, state) do
    events = Enum.map(events, fn {type, url, html} ->
      # Extract the URLs and filter ones we already found
      Krptkn.HtmlParser.get_urls(url, html)
      |> Enum.map(&Krptkn.UrlQueue.push/1)

      {:url, {type, url}}
    end)

    {:noreply, events, state}
  end
end
