defmodule Krptkn.Application do
  use Application

  @starting_page "https://ignisenergia.es/"
  @producers 6
  @consumers 6

  def start(_type, _args) do
    children = [
      # Start the URL queue
      {Krptkn.UrlQueue, @starting_page},

      # Start the connection to MongoD
      {Mongo, [name: :mongo, hostname: "127.0.0.1", database: "krptkn"]}
    ]

    # Start the producers
    {names, producers} = Enum.reduce(0..@producers-1, {[], []}, fn i, {n, p} ->
      name = String.to_atom("p#{i}")
      {
        [name | n],
        [Supervisor.child_spec({Krptkn.Spider, name}, id: name) | p]
      }
    end)
    children = children ++ producers

    # Start the consumers of URLs
    children = children ++ Enum.map(0..@consumers-1, fn i ->
      name = String.to_atom("cu#{i}")
      Supervisor.child_spec({Krptkn.ConsumerUrl, names}, id: name)
    end)

    # Start the consumers if metadata
    children = children ++ Enum.map(0..@consumers-1, fn i ->
      name = String.to_atom("cm#{i}")
      Supervisor.child_spec({Krptkn.ConsumerMetadata, names}, id: name)
    end)

    # Start the HTTP client
    HTTPoison.start()

    # {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get("https://pine64.com/wp-content/uploads/2020/09/PinecilS-1.png")
    # Extractor.extract(body)
    # |> Enum.map(fn {plugin_name, type, format, mime_type, data} ->
    #   data = List.to_string(data)
    #   if String.starts_with?(data, "\nexif") do
    #     {plugin_name, type, format, mime_type, Krptkn.PngExtractor.exifstr2map(data)}
    #   else
    #     {plugin_name, type, format, mime_type, data}
    #   end
    # end)
    # |> IO.inspect
    # Process.sleep(100_000)

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
