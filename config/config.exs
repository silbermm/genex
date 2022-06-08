import Config

config :mnesia,
dir: "HOME" |> System.get_env() |> Path.join(".genex") |> Path.join("db") |> String.to_charlist()

config :genex,
  homedir: "HOME" |> System.get_env() |> Path.join(".genex"),
  store: Genex.MnesiaStore
