import Config

config :mnesia,
dir: "HOME" |> System.get_env() |> Path.join(".genex") |> Path.join("db") |> String.to_charlist()

config :genex,
  homedir: "HOME" |> System.get_env() |> Path.join(".genex"),
  store: Genex.Store.Mnesia

config :logger, :console,
  level: :debug,
  format: "$time $metadata[$level] $levelpad$message\n",
  metadata: [:module]
