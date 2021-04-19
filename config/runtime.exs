import Config

if config_env() != :test do
  config :genex,
    genex_home: System.get_env("GENEX_HOME") || Path.join(System.get_env("HOME"), ".genex")
end
