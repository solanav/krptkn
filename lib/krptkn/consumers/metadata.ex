defmodule Krptkn.Consumers.Metadata do
  @moduledoc """
  This module defines the consumer that extracts the metadata of the files
  that the spider module downloads.
  """

  require Logger

  use GenStage

  def start_link(name) do
    Krptkn.Api.register_process(__MODULE__, name, self())
    GenStage.start_link(__MODULE__, [], name: name)
  end

  def init(_) do
    {:producer_consumer, :na, subscribe_to: [Krptkn.Distributors.Metadata]}
  end

  defp extract_metadata(buffer) do
    # Extract the metadata
    metadata = Extractor.flat_extract(buffer)
    |> Enum.map(fn metadata ->
      metadata
      |> Enum.filter(fn {_, type, _, _, _} ->
        Krptkn.MetadataFilter.interesting_type?(to_string(type))
      end)
      |> Enum.map(fn {_, type, _, _, data} ->
        data = to_string(data)
        if String.starts_with?(data, "\nexif") do
          {to_string(type), Krptkn.PngExtractor.exifstr2map(data)}
        else
          {to_string(type), data}
        end
      end)
      |> Map.new()
    end)
    |> Enum.filter(fn metadata ->
      map_size(metadata) > 0
    end)

    # Add the metadata to the UI
    Enum.map(metadata, fn dict ->
      Krptkn.Api.add_metadata(dict)
    end)

    metadata
  end

  def handle_events(events, _from, state) do
    # Extract the metadata and save it to events
    events = Enum.flat_map(events, fn {type, url, buffer} ->
      # Extract metadata from the file
      extract_metadata(buffer)
      |> Enum.uniq()
      # Remove empty values
      |> Enum.map(fn metadata ->
        Enum.filter(metadata, fn {_key, value} ->
          value != ""
        end)
        |> Map.new()
      end)
      |> Enum.filter(fn metadata ->
        res = Krptkn.MetadataFilter.interesting_data?(inspect(metadata))
        if res do
          Krptkn.Api.add(:danger)
          Krptkn.Api.add_dangerous_metadata(metadata)
        end
        res
      end)
      |> Enum.map(fn metadata ->
        {:metadata, {type, url, metadata}}
      end)
    end)
    # Remove empty maps
    |> Enum.filter(fn {:metadata, {_type, _url, m}} -> not Enum.empty?(m) end)
    # Count fmetadata
    |> Enum.map(fn v ->
      Krptkn.Api.add(:fmetadata)
      v
    end)

    {:noreply, events, state}
  end
end
