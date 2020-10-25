defmodule Krptkn.Spider.HtmlParser do
  require Logger

  def remove_file(%URI{path: path} = uri) do
    split_string = Regex.split(~r{\/}, path)

    # Divide by "/", remove the last and then rejoin them
    path = Enum.reverse(split_string)
    |> tl()
    |> Enum.reverse()
    |> Enum.reduce("", fn
      "", acc -> acc
      s, acc -> acc <> "/" <> s
    end)

    # Path will be empty on root directories
    path = case path do
      "" -> "/"
      p -> p
    end

    %{uri | path: path}
  end

  def add_defaults(%URI{host: host} = req_uri, string) do
    uri = URI.parse(string)

    # Add a default authority
    uri = case uri.authority do
      nil -> %{uri | authority: host}
      _ -> uri
    end

    # Add a default host
    uri = case uri.host do
      nil -> %{uri | host: host}
      _ -> uri
    end

    # Add a default scheme
    uri = case uri.scheme do
      nil -> %{uri | scheme: "https"}
      _ -> uri
    end

    # Add a default path
    uri = case uri.path do
      nil -> %{uri | path: "/"}
      "/" <> _ -> uri
      p ->
        %URI{path: path} = remove_file(req_uri)
        %{uri | path: path <> "/" <> p}
    end

    uri
  end

  def clear_url(%URI{path: path} = uri) do
    # Remove ./
    path = Regex.replace(~r/\.\//, path, "")

    # Remove ../
    path = Regex.replace(~r/[a-z|A-Z]+\/\.\.\//, path, "")

    # Remove fragment
    %{uri | fragment: nil, path: path}
  end

  def get_urls(req_url, string) do
    case Floki.parse_document(string) do
      {:ok, document} ->
        req_uri = URI.parse(req_url)
        req_uri = case req_uri.path do
          nil -> %{req_uri | path: "/"}
          _ -> req_uri
        end

        links = []

        # Add all the links to the list
        links = links ++ Floki.attribute(document, "a", "href")
        links = links ++ Floki.attribute(document, "area", "href")
        links = links ++ Floki.attribute(document, "base", "href")
        links = links ++ Floki.attribute(document, "link", "href")
        links = links ++ Floki.attribute(document, "img", "src")

        links
        |> Enum.map(&String.trim/1)
        # Complete the URI (missing paths, missing hosts, etc.)
        |> Enum.map(fn url -> add_defaults(req_uri, url) end)
        # Only visit URI of our same host
        |> Enum.filter(fn %URI{host: host} -> host == req_uri.host end)
        # Clean to avoid duplicates
        |> Enum.map(&clear_url/1)
        # Turn into string
        |> Enum.map(&URI.to_string/1)
      {:error, _err} ->
        Logger.error("Parser error")
        []
    end
  end
end
