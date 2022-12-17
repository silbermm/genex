import Config

config :genex, Genex.Repo,
  database: "genex_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :genex,
  halter: Genex.Utils.Halter.HalterDev
