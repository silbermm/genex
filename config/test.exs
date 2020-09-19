use Mix.Config

config :genex,
  system_module: Genex.Support.System,
  public_key: "priv/test/genex_public_test.pem",
  private_key: "priv/test/genex_private_test.pem",
  passwords_file: "priv/test/passwords"
