defmodule Krptkn.ConsumerMetadata do
  @moduledoc """
  This module defines the consumer that analyzes the metadata of the files
  that the spider module generates.
  """

  require Logger

  use GenStage

  def start_link(producers) do
    GenStage.start_link(__MODULE__, producers)
  end

  def init(producers) do
    producers = Enum.map(producers, fn prod ->
      {prod, max_demand: 1, min_demand: 0, selector: fn
        {:error, _u, _b} -> false
        {t, _u, _b} -> Regex.match?(~r{image\/.*}, t)
      end}
    end)

    # Our state will keep all producers and their pending demand
    {:consumer, :na, subscribe_to: producers}
  end

  def handle_events(events, _from, state) do
    # Consume the events
    for {type, url, buffer} <- events do
      metadata = Extractor.extract(buffer)
      |> Enum.map(fn {plugin_name, type, format, mime_type, data} ->
        data = List.to_string(data)
        if String.starts_with?(data, "\nexif") do
          {plugin_name, type, format, mime_type, Krptkn.PngExtractor.exifstr2map(data)}
        else
          {plugin_name, type, format, mime_type, data}
        end
      end)

      Logger.debug(inspect({type, url, metadata}))
    end

    {:noreply, [], state}
  end
end
