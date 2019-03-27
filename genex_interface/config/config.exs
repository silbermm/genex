# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :genex_interface, GenexInterfaceWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "pABR96apkHvTLu64oUFV8f4Cw/Ivd6/vd+qiYGIXwilRfii+oM9+wKaDj1cWC620",
  render_errors: [view: GenexInterfaceWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: GenexInterface.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "DVcyq+/CnOpaKNIUlE6ySZF9SmU5O8UN"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix, :template_engines, leex: Phoenix.LiveView.Engine

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
