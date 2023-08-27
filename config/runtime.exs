import Config

base_path = System.get_env("XDG_CONFIG_HOME") || System.get_env("HOME") |> Path.join(".config")

config :genex,
  homedir: base_path |> Path.join("genex")

config :mnesia,
  dir: base_path |> Path.join("genex") |> Path.join("db") |> String.to_charlist()

config :logger, :default_handler,
  config: [
    file: ~c"#{base_path}/genex/genex.log",
    filesync_repeat_interval: 5000,
    file_check: 5000,
    max_no_bytes: 10_000_000,
    max_no_files: 5,
    compress_on_rotate: true
  ],
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]
