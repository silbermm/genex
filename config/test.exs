use Mix.Config

config :genex_cli,
  system_module: Genex.Core.Support.System,
  public_key: "priv/test/genex_public_test.pem",
  private_key: "priv/test_/genex_private_test.pem",
  passwords_file: "priv/test/passwords"
