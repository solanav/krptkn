import Config

config :krptkn, Krptkn.Application,
  session_name: "stallman",
  starting_url: "http://uam.es/UAM/Home.htm?language=es",
  producers: 8,
  url_consumers: 4,
  metadata_consumers: 4

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n"

config :floki, :html_parser, Floki.HTMLParser.FastHtml
