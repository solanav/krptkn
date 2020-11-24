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

  def manual_start(initial_url) do
    initial_uri = URI.parse(initial_url)
    initial_urls = [initial_url | Krptkn.Prelaunch.dictionary(initial_uri)]

    for url <- initial_urls do
      Krptkn.UrlQueue.push(url)
    end
  end

  def start(_type, _args) do
    # Read the config to start the application
    initial_url = Application.get_env(:krptkn, Krptkn.Application)[:initial_url]
    producers = Application.get_env(:krptkn, Krptkn.Application)[:producers]
    url_consumers = Application.get_env(:krptkn, Krptkn.Application)[:url_consumers]
    metadata_consumers = Application.get_env(:krptkn, Krptkn.Application)[:metadata_consumers]
    db_consumers = Application.get_env(:krptkn, Krptkn.Application)[:db_consumers]

    initial_uri = URI.parse(initial_url)
    initial_urls = [initial_url | Krptkn.Prelaunch.dictionary(initial_uri)]

    children = [
      # Start the Ecto repository
      Krptkn.Repo,

      # Start the Telemetry supervisor
      KrptknWeb.Telemetry,

      # Start the PubSub system
      {Phoenix.PubSub, name: Krptkn.PubSub},

      # Start the Endpoint (http/https)
      KrptknWeb.Endpoint,

      # Start the API genserver
      Krptkn.Api,

      # Start the URL queue
      {Krptkn.UrlQueue, initial_urls},
    ]

    # Start the producers
    {spider_names, spider_producers} = Enum.reduce(0..producers-1, {[], []}, fn i, {n, p} ->
      num = String.pad_leading(Integer.to_string(i), 3, "0")
      name = String.to_atom("p" <> num)

      {
        [name | n],
        [Supervisor.child_spec({Krptkn.Spider, name}, id: name) | p]
      }
    end)
    children = children ++ spider_producers

    # Start the distributors and subscribe them to the producers
    children = children ++ [
      {Krptkn.Distributors.Url, spider_names},
      {Krptkn.Distributors.Metadata, spider_names},
    ]

    # Start the consumers of URLs and subscribe them to the url distributor
    {cu_names, cu} = Enum.reduce(0..url_consumers-1, {[], []}, fn i, {n, p} ->
      name = String.to_atom("cu#{i}")

      {
        [name | n],
        [Supervisor.child_spec({Krptkn.Consumers.Url, name}, id: name) | p]
      }
    end)
    children = children ++ cu

    # Start the consumers of metadata and subscribe them to the metadata distributor
    {cm_names, cm} = Enum.reduce(0..metadata_consumers-1, {[], []}, fn i, {n, p} ->
      name = String.to_atom("cm#{i}")

      {
        [name | n],
        [Supervisor.child_spec({Krptkn.Consumers.Metadata, name}, id: name) | p]
      }
    end)
    children = children ++ cm

    # Start the distributor for the database inserters
    children = children ++ [
      {Krptkn.Distributors.Db, cu_names ++ cm_names}
    ]

    # Start the consumers of database data and subscribe them to the db distributor
    children = children ++ Enum.map(0..db_consumers-1, fn i ->
      name = String.to_atom("cdb#{i}")
      Supervisor.child_spec({Krptkn.Consumers.Db, []}, id: name)
    end)

    # Start the HTTP client
    HTTPoison.start()

    opts = [strategy: :one_for_one, name: Krptkn.Supervisor]

    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    KrptknWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
