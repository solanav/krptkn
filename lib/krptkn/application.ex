defmodule Krptkn.Application do
  use Application

  @starting_page "https://pine64.com/?v=0446c16e2e66"
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

    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get("https://pine64.com/wp-content/uploads/2020/09/Pinebook.png")
    {:ok, data} = Krptkn.Metadata.PngExtractor.extract_from_png_buffer(body)

    z = :zlib.open()

    :zlib.inflateInit(z)
    <<type::8, zlib_text::binary()>> = data["Raw profile type exif"]

    :zlib.inflate(z, zlib_text)
    |> IO.inspect

    :zlib.inflateEnd(z)

    Process.sleep(100_000)

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
