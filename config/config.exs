import Config

config :krptkn, Krptkn.Application,
  session_name: "debugging_001",
  starting_url: "https://www.tumblr.com/",
  producers: 8,
  url_consumers: 16,
  metadata_consumers: 1,
  db_consumers: 8

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n"

config :floki, :html_parser, Floki.HTMLParser.FastHtml
import_config "appsignal.exs"
