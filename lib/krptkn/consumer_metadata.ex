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

  defp interesting_data?(data) do
    # Return true if the data is interesting and false if it is boring

    boring_data = [
      "sof-marker",
    ]

    if data == "" do
      false
    else
      not Enum.reduce(boring_data, false, fn
        _, true -> true
        bd, _ -> String.contains?(data, bd)
      end)
    end
  end

  defp interesting_type?(type) do
    boring_types = [
      "mimetype",
      "image dimensions",
      "video dimensions",
      "video depth",
      "pixel aspect ratio",
      "thumbnail",
      "sample rate",
      "duration",
      "audio bitrate",
      "container format",
      "orientation",
      "exposure bias",
      "flash",
      "flash bias",
      "focal length",
      "iso speed",
      "macro mode",
      "image quality",
      "white balance",
      "aperture",
      "exposure",
      "exposure mode",
      "metering mode",
      "audio codec",
      "audio depth",
      "channels",
    ]

    not Enum.member?(boring_types, type)
  end

  def handle_events(events, _from, state) do
    # Consume the events
    for {type, url, buffer} <- events do
      metadata = Extractor.extract(buffer)
      |> IO.inspect
      |> Enum.filter(fn {_, type, _, _, _} -> interesting_type?(to_string(type)) end)
      |> Enum.filter(fn {_, _, _, _, data} -> interesting_data?(to_string(data)) end)
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
