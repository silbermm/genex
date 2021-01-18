use Mix.Config

config :genex,
  genex_home: Path.join(System.get_env("HOME"), ".genex"),
  encryption_module: Genex.Encryption.RSA,
  passwords_file: System.get_env("HOME") <> "/" <> ".genex/passwords",
  public_key: System.get_env("HOME") <> "/" <> ".genex/public_key.pem",
  private_key: System.get_env("HOME") <> "/" <> ".genex/private_key.pem",
  manifest_file: System.get_env("HOME") <> "/" <> ".genex/manifest"

import_config "#{Mix.env()}.exs"
