import Config

config :krptkn, Krptkn.Application,
  session_name: "debugging_002",
  starting_url: "https://archive.synology.com/download/",
  producers: 32,
  url_consumers: 32,
  metadata_consumers: 1,
  db_consumers: 8

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n"

config :floki, :html_parser, Floki.HTMLParser.FastHtml
import_config "appsignal.exs"
