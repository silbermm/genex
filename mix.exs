defmodule Genex.MixProject do
  use Mix.Project

  def project do
    [
      app: :genex,
      version: "0.0.5-beta",
      releases: releases(),
      elixir: "~> 1.15.2",
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
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64]
          ]
        ]
      ]
    ]
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
      {:prompt, "~> 0.9"},
      # {:prompt, path: "../prompt"},
      {:clipboard, "~> 0.2.1"},
      {:ratatouille, "~> 0.5"},
      {:jason, "~> 1.2"},
      {:gpgmex, "~> 0.0.11"},
      # {:gpgmex, path: "../gpgmex"},
      {:req, "~> 0.3.1", override: true},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ecto_sql, "~> 3.10.1"},
      {:ecto_sqlite3, ">= 0.0.0"},
      {:burrito, github: "burrito-elixir/burrito"}
    ]
  end
end
