defmodule Krptkn.Application do
  use Application

  def start(_type, _args) do
    # Read the config to start the application
    starting_page = Application.get_env(:krptkn, Krptkn.Application)[:starting_url]
    producers = Application.get_env(:krptkn, Krptkn.Application)[:producers]
    url_consumers = Application.get_env(:krptkn, Krptkn.Application)[:url_consumers]
    metadata_consumers = Application.get_env(:krptkn, Krptkn.Application)[:metadata_consumers]

    children = [
      # Start the URL queue
      {Krptkn.UrlQueue, starting_page},

      # Start the connection to MongoD
      {Mongo, [name: :mongo, hostname: "127.0.0.1", database: "krptkn"]}
    ]

    # Start the producers
    {names, producers} = Enum.reduce(0..producers-1, {[], []}, fn i, {n, p} ->
      num = String.pad_leading(Integer.to_string(i), 3, "0")
      name = String.to_atom("p" <> num)

      {
        [name | n],
        [Supervisor.child_spec({Krptkn.Spider, name}, id: name) | p]
      }
    end)
    children = children ++ producers

    # Start the distributors and subscribe them to the producers
    children = children ++ [
      {Krptkn.DistributorUrl, names},
      {Krptkn.DistributorMetadata, names},
    ]

    # Start the consumers of URLs and subscribe them to the url distributor
    children = children ++ Enum.map(0..url_consumers-1, fn i ->
      name = String.to_atom("cu#{i}")
      Supervisor.child_spec({Krptkn.ConsumerUrl, []}, id: name)
    end)

    # Start the consumers if metadata and subscribe them to the metadata distributor
    children = children ++ Enum.map(0..metadata_consumers-1, fn i ->
      name = String.to_atom("cm#{i}")
      Supervisor.child_spec({Krptkn.ConsumerMetadata, []}, id: name)
    end)

    # Start the HTTP client
    HTTPoison.start()

    #{:ok, %HTTPoison.Response{body: body}} = HTTPoison.get("https://uam.es/UAM/imagen424/1446810134146/2020_10_30_Izquierdo_web.jpg")
    #Extractor.extract(body)
    #|> Enum.map(fn {plugin_name, type, format, mime_type, data} ->
    #  data = List.to_string(data)
    #  if String.starts_with?(data, "\nexif") do
    #    {plugin_name, type, format, mime_type, Krptkn.PngExtractor.exifstr2map(data)}
    #  else
    #    {plugin_name, type, format, mime_type, data}
    #  end
    #end)
    #|> IO.inspect
    #Process.sleep(100_000)

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
