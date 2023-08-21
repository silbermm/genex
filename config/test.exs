import Config

config :genex,
  halter: Genex.Utils.Halter.HalterDev

config :mnesia,
  dir:
    "priv" |> Path.join("testhome") |> Path.join("db") |> String.to_charlist()

config :genex,
  homedir: "priv" |> Path.join("testhome")


