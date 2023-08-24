import Config

base_path = System.get_env("XDG_CONFIG_HOME") || System.get_env("HOME") |> Path.join(".config")

config :genex,
  homedir: base_path |> Path.join("genex")

config :mnesia,
  dir: base_path |> Path.join("genex") |> Path.join("db") |> String.to_charlist()
