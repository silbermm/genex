use Mix.Config

config :genex_cli,
  encryption_module: Genex.Core.Encryption.RSA,
  random_number_module: Genex.Core.RandomNumber,
  passwords_file: System.get_env("HOME") <> "/" <> ".genex/passwords",
  public_key: System.get_env("HOME") <> "/" <> ".genex/public_key.pem",
  private_key: System.get_env("HOME") <> "/" <> ".genex/private_key.pem"

config :genex_cli,
  system_module: System,
  genex_core_module: Genex.Core

import_config "#{Mix.env()}.exs"
