defmodule Krptkn.ConsumerMetadata do
  @moduledoc """
  This module defines the consumer that analyzes the metadata of the files
  that the spider module generates.
  """

  require Logger

  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, [])
  end

  def init(_) do
    {:consumer, :na, subscribe_to: [Krptkn.DistributorMetadata]}
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

      Logger.debug(inspect({self(), type, url, metadata}))
    end

    {:noreply, [], state}
  end
end
