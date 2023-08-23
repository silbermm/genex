defmodule Genex.MixProject do
  use Mix.Project

  def project do
    [
      app: :genex,
      version: "0.0.10-alpha",
      releases: releases(),
      elixir: "~> 1.15.2",
      dialyzer: [
        plt_add_apps: [:mnesia]
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
      extra_applications: [:logger, :prompt, :ratatouille, :gpgmex],
      included_applications: [:mnesia],
      mod: {Genex.Application, env: Mix.env()}
    ]
  end

  defp deps do
    [
      {:burrito, github: "burrito-elixir/burrito"},
      {:clipboard, "~> 0.2.1"},
      {:diceware, "~> 0.2.9"},
      {:gpgmex, "~> 0.1.1"},
      # {:gpgmex, path: "../gpgmex"},
      {:owl, "~> 0.7.0"},
      {:prompt, "~> 0.9.3"},
      # {:prompt, path: "../prompt"},
      {:ratatouille, "~> 0.5"},
      {:req, "~> 0.3.1", override: true},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:mox, "~> 1.0", only: [:test, :ci], runtime: false}
    ]
  end
end
