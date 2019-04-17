use Mix.Config

config :genex_core,
  encryption_module: GenexCore.Encryption.RSA,
  random_number_module: GenexCore.RandomNumber,
  passwords_file: System.get_env("HOME") <> "/" <> ".genex/passwords",
  public_key: System.get_env("HOME") <> "/" <> ".genex/public_key.pem",
  private_key: System.get_env("HOME") <> "/" <> ".genex/private_key.pem"
  
config :genex_core, :server,
  port: String.to_integer(System.get_env("PORT") || "5555")

config :logger,
  level: :debug

import_config "#{Mix.env()}.exs"
