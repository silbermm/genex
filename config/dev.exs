import Config

config :genex,
  halter: Genex.Utils.Halter.HalterDev

config :logger,
  backends: [{LoggerFileBackend, :debug_log}]

config :logger, :debug_log,
  path: "debug.log",
  level: :debug,
  format: "$time $metadata[$level] $message\n",
  metadata: [:module]
