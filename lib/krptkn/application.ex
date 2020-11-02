defmodule Krptkn.Application do
  use Application

  import ExProf.Macro

  def test do
    profile do
      url = "https://uam.es/UAM/documento/1446806015659/Codigo_etico_UAM.pdf"
      {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url)
      Extractor.extract(body)
      |> Enum.map(fn {plugin_name, type, format, mime_type, data} ->
        data = List.to_string(data)
        if String.starts_with?(data, "\nexif") do
          [
            List.to_string(plugin_name),
            List.to_string(type),
            format,
            List.to_string(mime_type),
            Krptkn.PngExtractor.exifstr2map(data)
          ]
        else
          [
            List.to_string(plugin_name),
            List.to_string(type),
            format,
            List.to_string(mime_type),
            data
          ]
        end
      end)
      |> IO.inspect
    end
  end

  def start(_type, _args) do
    # Read the config to start the application
    starting_page = Application.get_env(:krptkn, Krptkn.Application)[:starting_url]
    producers = Application.get_env(:krptkn, Krptkn.Application)[:producers]
    url_consumers = Application.get_env(:krptkn, Krptkn.Application)[:url_consumers]
    metadata_consumers = Application.get_env(:krptkn, Krptkn.Application)[:metadata_consumers]

    children = [
      # Start the URL queue
      {Krptkn.UrlQueue, starting_page},

      # Start the database wrapper
      Krptkn.Db,

      # Start the connection to Postgresql
      {Postgrex, [
        name: :psql,
        hostname: "localhost",
        username: "postgres",
        password: "1234",
        database: "krptkn",
        pool_size: 10,
      ]},
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

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
