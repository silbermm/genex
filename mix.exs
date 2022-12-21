defmodule Genex.MixProject do
  use Mix.Project

  def project do
    [
      app: :genex,
      version: "0.0.5-alpha",
      releases: releases(),
      elixir: "~> 1.13",
      dialyzer: [
        plt_add_apps: []
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def releases do
    [
      genex: [
        strip_beams: [keep: ["Docs"]],
        steps: [:assemble, &copy_bin_files/1, :tar]
      ]
    ]
  end

  defp copy_bin_files(release) do
    File.cp_r("rel/bin/", Path.join(release.path, "bin"))
    release
  end

  def application do
    [
      extra_applications: [:logger, :prompt, :ratatouille],
      mod: {Genex.Application, env: Mix.env()}
    ]
  end

  defp deps do
    [
      {:diceware, "~> 0.2.8"},
      # {:prompt, path: "../prompt"},
      {:prompt, "~> 0.8"},
      {:clipboard, "~> 0.2.1"},
      {:ratatouille, "~> 0.5"},
      {:vapor, "~> 0.10.0"},
      {:jason, "~> 1.2"},
      {:gpgmex, "~> 0.0.8"},
      {:req, "~> 0.3.1"},
      # {:gpgmex, path: "../gpgmex"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:logger_file_backend, "~> 0.0.13"},
      {:ecto_sql, "~> 3.6"},
      {:ecto_sqlite3, ">= 0.0.0"}
    ]
  end
end
