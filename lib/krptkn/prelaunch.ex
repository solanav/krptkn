defmodule Krptkn.Prelaunch do
  def robotstxt(uri, text) do
    Regex.scan(~r/Disallow:(.*)/, text)
    |> Enum.map(fn [_, value] -> String.trim(value) end)
    |> Enum.filter(fn path -> not String.contains?(path, "*") end)
    |> Enum.map(fn path -> %{uri | path: path} end)
    |> Enum.map(&URI.to_string/1)
  end

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