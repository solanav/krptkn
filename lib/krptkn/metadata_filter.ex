defmodule Krptkn.MetadataFilter do
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

  #defp extract_emails(string) do
  #  email_regex = ~r/([a-zA-Z0-9+._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/
  #  Enum.at(Regex.scan(email_regex, string), 0)
  #  |> Enum.uniq()
  #end

  def interesting_data?(string) do
    keywords = [
      "password",
      "user",
      "username",
      "email",
      "token",
      "key",
      "api",
      "address",
      "ip",
      "hash",
      "protocol",
      "access",
      "maintainer",
      "name",
      "software",
      "comment",
    ]

    String.contains?(string, keywords)
  end
end
