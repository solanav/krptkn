import Config

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n"

config :floki, :html_parser, Floki.HTMLParser.FastHtml
