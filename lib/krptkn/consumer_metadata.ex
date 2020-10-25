defmodule Krptkn.ConsumerMetadata do
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

  defp handle_jpg(buffer) do
    case Exexif.exif_from_jpeg_buffer(buffer) do
      {:ok, exif} -> Krptkn.Db.insert_mongo("exif_jpg", exif)
      _ -> Logger.info("No exif on jpg")
    end
  end

  defp handle_png(buffer) do
    case Krptkn.Metadata.PngExtractor.extract_from_png_buffer(buffer) do
      {:ok, exif} ->
        exif = Enum.map(exif, fn
          {key, data} when is_binary(data) ->
            if String.valid?(data) do
              {key, data}
            else
              {key, %BSON.Binary{binary: data, subtype: :generic}}
            end
        end)

        Krptkn.Db.insert_mongo("exif_png", exif)
      _ -> Logger.info("No exif on png")
    end
  end

  def handle_events(events, _from, state) do
    # Consume the events
    for {type, _url, buffer} <- events do
      case type do
        "image/jpg" -> handle_jpg(buffer)
        "image/jpeg" -> handle_jpg(buffer)
        "image/png" -> handle_png(buffer)
        t -> Logger.info("Filetype not supported: #{t}")
      end
    end

    {:noreply, [], state}
  end
end
