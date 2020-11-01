import Config

config :krptkn, Krptkn.Application,
  session_name: "stallman",
  starting_url: "https://stallman.org/civillibertiesminute/",
  producers: 64,
  url_consumers: 128,
  metadata_consumers: 128

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n"

config :floki, :html_parser, Floki.HTMLParser.FastHtml
