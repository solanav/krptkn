defmodule Krptkn.ConsumerUrl do
  @moduledoc """
  This module defines the consumer that extracts URLs from the files
  that the spider module generates. After extracting the URLs, they are put
  into a global queue that the producer can pop from.
  """

  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, [])
  end

  def init(_) do
    {:consumer, :na, subscribe_to: [Krptkn.DistributorUrl]}
  end

  def handle_events(events, _from, state) do
    # Consume the events
    for {_type, url, html} <- events do
      Krptkn.HtmlParser.get_urls(url, html)
      |> Enum.map(&Krptkn.UrlQueue.push/1)
    end

    {:noreply, [], state}
  end
end
