defmodule Krptkn.DistributorMetadata do
  use GenStage

  require Logger

  def start_link(producers) do
    GenStage.start_link(__MODULE__, producers, name: __MODULE__)
  end

  def init(producers) do
    producers = Enum.map(producers, fn prod ->
      {prod, max_demand: 1, min_demand: 0, selector: fn
        {:error, _u, _b} -> false
        {t, _u, _b} -> not String.contains?(t, "text/html")
      end}
    end)

    {:producer_consumer, :na, subscribe_to: producers}
  end

  def handle_events(events, _from, producers) do
    {:noreply, events, producers}
  end
end
