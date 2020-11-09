defmodule Krptkn.MetadataFilter do
  def interesting_data?(data) do
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

  def interesting_type?(type) do
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

  def extract_data(string) do

  end
end