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
      # Remove metadata with uninteresting types
      |> Enum.filter(fn {_, type, _, _, _} ->
        Krptkn.MetadataFilter.interesting_type?(to_string(type))
      end)
      # Some PNGs have compressed EXIF, extract it
      |> Enum.map(fn {_, type, _, _, data} ->
        data = if String.starts_with?(to_string(data), "\nexif") do
          Krptkn.Parsers.Png.exifstr2map(data)
        end

        {to_string(type), data}
      end)
      # Clean stuff
      |> Enum.filter(fn {_type, data} -> data != "" end)
      # Turn the list of key-values into a map
      |> Map.new()
    end)
    |> Enum.uniq()
    |> Enum.filter(&(map_size(&1) > 0))
    |> Enum.map(Krptkn.Api.add_metadata)

    metadata
  end

  def handle_events(events, _from, state) do
    # Extract the metadata and save it to events
    events = Enum.flat_map(events, fn {type, url, buffer} ->
      # Extract metadata from the file
      extract_metadata(buffer)
      |> Enum.filter(Enum.empty?)
      # Mark metadata if its dangerous
      |> Enum.map(fn metadata ->
        dangerous = Krptkn.MetadataFilter.interesting_data?(inspect(metadata))

        if dangerous do
          Krptkn.Api.add(:danger)
          Krptkn.Api.add_dangerous_metadata(metadata)
        end

        {:metadata, {type, url, metadata, dangerous}}
      end)
    end)
    # Count metadata that has passed all filters
    |> Enum.each(fn -> Krptkn.Api.add(:fmetadata) end)

    {:noreply, events, state}
  end
end
