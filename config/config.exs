import Config

config :genex,
  homedir: "HOME" |> System.get_env() |> Path.join(".genex")
