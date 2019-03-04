use Mix.Config

config :genex,
  encryption_module: Genex.Encryption.RSA,
  random_number_module: Genex.RandomNumber,
  passwords_file: System.get_env("HOME") <> "/" <> ".genex/passwords",
  public_key: System.get_env("HOME") <> "/" <> ".genex/public_key.pem",
  private_key: System.get_env("HOME") <> "/" <> ".genex/private_key.pem",
  system_module: System

import_config "#{Mix.env()}.exs"
