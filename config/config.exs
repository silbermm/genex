import Config

config :genex,
  genex_home: Path.join(System.get_env("HOME"), ".genex"),
  encryption_module: Genex.Encryption.RSA

import_config "#{Mix.env()}.exs"
