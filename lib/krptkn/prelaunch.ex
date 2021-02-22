defmodule Krptkn.Prelaunch do
  @moduledoc """
  Useful functions to run on the starting URL, so the URL queue fills up faster.
  This will also help discover non-linked pages of a website.
  """

  @doc """
  Checks the pages listed on Robots.txt.

  Returns a list of strings.

  ## Examples

      iex> Krptkn.Prelaunch.robotstxt("https://stallman.org/", "Example robots.txt file data")
      [
        "https://stallman.org/admin/",
        "https://stallman.org/private-images/",
      ]

  """
  def robotstxt(uri, text) do
    Regex.scan(~r/Disallow:(.*)/, text)
    |> Enum.map(fn [_, value] -> String.trim(value) end)
    |> Enum.filter(fn path -> not String.contains?(path, "*") end)
    |> Enum.map(fn path -> %{uri | path: path} end)
    |> Enum.map(&URI.to_string/1)
  end

  @doc """
  Provides a list of common URLs to check.

  Returns a list of strings.

  ## Examples

      iex> Krptkn.Prelaunch.dictionary("https://stallman.org/")
      [
        "https://stallman.org/wp-content/",
        "https://stallman.org/wp-content/plugins/",
        "https://stallman.org/uploads/",
      ]

  """
  def dictionary(uri) do
    common_urls = [
      "/wp-content/",
      "/wp-content/plugins/",
      "/wp-content/themes/",
      "/uploads/",
      "/images/",
      "/css/",
      "/LC_MESSAGES/",
      "/js/",
      "/tmpl/",
      "/lang/",
      "/default/",
      "/README/",
      "/templates/",
      "/langs/",
      "/config/",
      "/GNUmakefile/",
      "/themes/",
      "/en/",
      "/img/",
      "/admin/",
      "/user/",
      "/plugins/",
      "/show/",
    ]

    Enum.map(common_urls, fn url -> %{uri | path: url} end)
    |> Enum.map(&URI.to_string/1)
  end
end
