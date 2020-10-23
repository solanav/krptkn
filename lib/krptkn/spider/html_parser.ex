defmodule Krptkn.Spider.HtmlParser do
  def remove_file(string) do
    split_string = Regex.split(~r{\/}, string)

    # Check the length so we don't remove the domain
    if Enum.count(split_string) > 3 do
      Enum.reverse(split_string)
      |> tl()
      |> Enum.reverse()
      |> Enum.reduce("", fn
        s, "" -> s <> "/"
        s, acc -> acc <> "/" <> s
      end)
    else
      string
    end
  end

  def url?(string) do
    Regex.match?(~r{https?:\/\/.*}, string)
  end

  def base_url(string) do
    Regex.split(~r{\/}, string)
    |> Enum.slice(0..2)
    |> Enum.reduce("", fn
      s, "" -> s
      s, acc -> acc <> "/" <> s
    end)
  end

  def classify_link(string) do
    if url?(string) do
      {:external, string}
    else
      case string do
        "#" <> text -> {:local, "#" <> text}
        "/" <> text -> {:absolute, "/" <> text}
        text -> {:relative, text}
      end
    end
  end

  def clear_url(string) do
    Regex.split(~r{#}, string)
    |> Enum.at(0)
  end

  def html?(string) do
    Regex.match?(~r{\.html$}, string)
  end

  def get_urls(req_url, string) do
    {:ok, document} = Floki.parse_document(string)

    # Get all the links in the document
    Floki.attribute(document, "a", "href")
    |> Enum.map(&classify_link/1)
    |> Enum.filter(fn
      {:local, _} -> false
      {:external, _} -> false
      {:absolute, _} -> true
      {:relative, _} -> true
    end)
    |> Enum.map(fn
      {:absolute, text} -> base_url(req_url) <> text
      {:relative, text} -> remove_file(req_url) <> "/" <> text
    end)
    |> Enum.map(&clear_url/1)
    |> Enum.filter(&html?/1)
  end
end
