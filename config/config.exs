import Config

config :krptkn, Krptkn.Application,
  session_name: "sparkfun",
  starting_url: "https://www.sparkfun.com/",
  producers: 8,
  url_consumers: 4,
  metadata_consumers: 4

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n"

config :floki, :html_parser, Floki.HTMLParser.FastHtml
import_config "appsignal.exs"
