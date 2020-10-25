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

    data = :zlib.inflate(z, zlib_text)
    |> Enum.at(0)
    |> String.split("\n")
    |> IO.inspect()

    bin = Enum.slice(data, 3..Enum.count(data))
    |> Enum.flat_map(fn p ->
      String.codepoints(p)
      |> Enum.chunk_every(2)
      |> Enum.map(fn [a, b] ->
        {num, s} = Integer.parse(a <> b, 16)
        num
      end)
    end)
    |> :binary.list_to_bin()

    bin = <<0xFFE17414::32>> <> bin

    Exexif.read_exif(bin)
    |> IO.inspect()

    :zlib.inflateEnd(z)

    Process.sleep(100_000)

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
