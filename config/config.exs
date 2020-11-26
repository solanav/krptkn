# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :krptkn,
  ecto_repos: [Krptkn.Repo]

# Configure the application
config :krptkn, Krptkn.Application,
  session_name: "debugging_002",
  initial_url: "https://archive.synology.com/download/",
  producers: 16,
  url_consumers: 16,
  metadata_consumers: 1,
  db_consumers: 16

# Configure the HTML parser
config :floki, :html_parser, Floki.HTMLParser.FastHtml

# Configures the endpoint
config :krptkn, KrptknWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MbTK/IuXWb/0pxzCdiVXmfMvoFfK7U0mq2eg2i1hxLCerViBx2ycOaE6tsQQnUmh",
  render_errors: [view: KrptknWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Krptkn.PubSub,
  live_view: [signing_salt: "mdIyiHvl"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
