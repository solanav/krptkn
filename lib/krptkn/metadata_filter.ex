defmodule Krptkn.MetadataFilter do
  @moduledoc """
  This module provides functions to mark metadata as dangerous or as not interesting.
  """

  @doc """
  Checks if a type of metadata is known to be not useful or uninteresting.

  Returns `true` or `false`.

  ## Examples

      iex> Krptkn.MetadataFilter.interesting_type?(string)
      true

  """
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

  @doc """
  Extracts email addresses from a string.

  Returns a list of strings.

  ## Examples

      iex> Krptkn.MetadataFilter.extract_emails(string)
      [
        "aasdas.jqoweij@gmail.com",
        "software_libre@gnu.org",
      ]

  """
  def extract_emails(string) do
    email_regex = ~r/([a-zA-Z0-9+._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/
    Enum.at(Regex.scan(email_regex, string), 0)
    |> Enum.uniq()
  end

  @doc """
  Checks if a string contains potentially dangerous or interesting data.

  Returns `true` or `false`.

  ## Examples

      iex> Krptkn.MetadataFilter.interesting_data?(string)
      true

  """
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
      "@"
    ]

    String.contains?(string, keywords)
  end
end
