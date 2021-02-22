defmodule Krptkn.Application do
  use Application

  require Logger

  def manual_start(initial_url) do
    initial_uri = URI.parse(initial_url)
    initial_urls = [initial_url | Krptkn.Prelaunch.dictionary(initial_uri)]

    for url <- initial_urls do
      Krptkn.UrlQueue.push(url)
    end
  end

  def start(_type, _args) do
    # Read the config to start the application
    producers = Application.get_env(:krptkn, Krptkn.Application)[:producers]
    url_consumers = Application.get_env(:krptkn, Krptkn.Application)[:url_consumers]
    metadata_consumers = Application.get_env(:krptkn, Krptkn.Application)[:metadata_consumers]
    db_consumers = Application.get_env(:krptkn, Krptkn.Application)[:db_consumers]

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
      {Krptkn.UrlQueue, []},
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

    # Start the observer for ets et al
    # :observer.start()

    opts = [
      strategy: :one_for_one,
      max_restarts: 100,
      max_seconds: 1,
      name: Krptkn.Supervisor,
    ]

    {:ok, pid} = Supervisor.start_link(children, opts)

    # Monitor stuff
    Supervisor.which_children(Krptkn.Supervisor)
    |> Enum.map(fn
      {_, :restarting, _, _} -> :ok
      {_, :undefined, _, _} -> :ok
      {_name, child, _, _} -> Process.monitor(child)
    end)

    receive do
      msg -> Logger.error(inspect(msg))
    end

    {:ok, pid}
  end

  def config_change(changed, _new, removed) do
    KrptknWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def handle_info(msg, state) do
    Logger.error("Supervisor received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
