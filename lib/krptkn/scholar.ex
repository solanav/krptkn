defmodule Krptkn.Scholar do
  use GenStage

  def start_link(producers) do
    GenStage.start_link(__MODULE__, producers)
  end

  def init(producers) do
    producers = Enum.map(producers, fn prod ->
      {prod, max_demand: 1, min_demand: 0}
    end)

    # Our state will keep all producers and their pending demand
    {:consumer, :na, subscribe_to: producers}
  end

  def handle_events(events, _from, state) do
    # Consume the events
    for {url, html} <- events do
      Krptkn.Spider.HtmlParser.get_urls(url, html)
      |> Enum.map(fn url -> Krptkn.UrlQueue.push(url) end)
    end

    # A producer_consumer would return the processed events here.
    {:noreply, [], state}
  end
end
