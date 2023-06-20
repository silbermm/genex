import Config

config :genex, Genex.Repo,
  database:
    "HOME" |> System.get_env() |> Path.join(".genex") |> Path.join("db") |> Path.join("genex.db")

config :genex,
  ecto_repos: [Genex.Repo]

config :genex,
  homedir: "HOME" |> System.get_env() |> Path.join(".genex")

config :logger, :default_handler,
  config: [
    file: ~c"#{System.get_env("HOME")}/.genex/genex.log",
    filesync_repeat_interval: 5000,
    file_check: 5000,
    max_no_bytes: 10_000_000,
    max_no_files: 5,
    compress_on_rotate: true
  ]

config :clipboard,
  unix: [
    copy: {"xclip", ["-sel", "clip"]}
  ]

config :gpgmex,
  gpg_bin: "/usr/bin/gpg",
  gpg_home: "~/.gnupg"

import_config "#{Mix.env()}.exs"
