defmodule Krptkn.ConsumerUrl do
  @moduledoc """
  This module defines the consumer that extracts URLs from the files
  that the spider module generates. After extracting the URLs, they are put
  into a global queue that the producer can pop from.
  """

  use GenStage

  def start_link(producers) do
    GenStage.start_link(__MODULE__, producers)
  end

  def init(producers) do
    producers = Enum.map(producers, fn prod ->
      {prod, max_demand: 1, min_demand: 0, selector: fn {t, _u, _b} ->
        t == :error or String.contains?(t, "text/html")
      end}
    end)

    # Our state will keep all producers and their pending demand
    {:consumer, :na, subscribe_to: producers}
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
