import Config

config :krptkn, Krptkn.Application,
  starting_url: "https://uam.es",
  producers: 256,
  url_consumers: 128,
  metadata_consumers: 1

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n"

config :floki, :html_parser, Floki.HTMLParser.FastHtml
