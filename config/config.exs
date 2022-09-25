import Config

config :mnesia,
  dir:
    "HOME" |> System.get_env() |> Path.join(".genex") |> Path.join("db") |> String.to_charlist()

config :genex,
  homedir: "HOME" |> System.get_env() |> Path.join(".genex"),
  store: Genex.Store.Mnesia

config :logger,
  backends: [{LoggerFileBackend, :error_log}]

config :logger, :error_log,
  path: "/var/log/genex/error.log",
  level: :error,
  format: "$time $metadata[$level] $levelpad$message\n",
  metadata: [:module]

config :clipboard,
  unix: [
    copy: {"xclip", ["-sel", "clip"]}
  ]

config :gpgmex,
  include_dir: ["/usr/include/x86_64-linux-gnu", "/usr/include"],
  libs_dir: ["/usr/lib/x86_64-linux-gnu/libgpgme.so"]

import_config "#{Mix.env()}.exs"
