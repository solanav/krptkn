defmodule Krptkn.Consumers.Metadata do
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
    {:consumer, :na, subscribe_to: [Krptkn.Distributors.Metadata]}
  end

  def handle_events(events, _from, state) do
    # Consume the events
    for {type, url, buffer} <- events do
      metadata = Extractor.extract(buffer)
      |> IO.inspect
      |> Enum.filter(fn {_, type, _, _, _} -> Krptkn.MetadataFilter.interesting_type?(to_string(type)) end)
      |> Enum.filter(fn {_, _, _, _, data} -> Krptkn.MetadataFilter.interesting_data?(to_string(data)) end)
      |> Enum.map(fn {_, type, _, _, data} ->
        data = to_string(data)
        if String.starts_with?(data, "\nexif") do
          {to_string(type), Krptkn.PngExtractor.exifstr2map(data)}
        else
          {to_string(type), data}
        end
      end)
      |> Map.new()

      if metadata != %{} do
        Enum.map(metadata, fn {type, data} -> Logger.debug("#{type} >>> #{data}") end)
        Krptkn.Db.insert_metadata(url, type, metadata)
      end
    end

    {:noreply, [], state}
  end
end
