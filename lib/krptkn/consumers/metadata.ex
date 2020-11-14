defmodule Krptkn.Consumers.Metadata do
  @moduledoc """
  This module defines the consumer that extracts the metadata of the files
  that the spider module downloads.
  """

  require Logger

  use GenStage

  def start_link(name) do
    GenStage.start_link(__MODULE__, [], name: name)
  end

  def init(_) do
    {:producer_consumer, :na, subscribe_to: [Krptkn.Distributors.Metadata]}
  end

  defp extract_metadata(buffer) do
    Extractor.flat_extract(buffer)
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
  end

  def handle_events(events, _from, state) do
    # Extract the metadata and save it to events
    events = Enum.map(events, fn {type, url, buffer} ->
      # Extract metadata from the file
      metadata = extract_metadata(buffer)

      {:metadata, {type, url, metadata}}
    end)
    # Remove the empty maps
    |> Enum.filter(fn {:metadata, {_type, _url, m}} -> not Enum.empty?(m) end)

    {:noreply, events, state}
  end
end
