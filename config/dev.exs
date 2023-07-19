import Config

config :genex,
  halter: Genex.Utils.Halter.HalterDev

config :logger, :default_handler,
  config: [
    file: ~c"debug.log",
    filesync_repeat_interval: 5000,
    file_check: 5000,
    max_no_bytes: 10_000_000,
    max_no_files: 5,
    compress_on_rotate: true
  ]
