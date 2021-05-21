defmodule GenexCli.MixProject do
  use Mix.Project

  @app :genex

  def project do
    [
      app: @app,
      version: "0.0.3-alpha",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: [release: :prod],
      releases: [
        genex: [
          steps: [:assemble, &Bakeware.assemble/1]
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    if Mix.env() == :test || Mix.env() == :dev do
      [
        extra_applications: [:logger, :public_key]
      ]
    else
      [
        extra_applications: [:logger, :public_key],
        mod: {Genex.Application, [env: Mix.env()]}
      ]
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"},
      {:gettext, ">= 0.0.0"},
      {:bakeware, "~> 0.2.0"},
      {:elixir_uuid, "~> 1.2"},
      {:sshex, "2.2.1"},
      {:diceware, "~> 0.2.8"},
      {:prompt, "~> 0.5.6"},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:mox, "~> 0.5", only: :test}
    ]
  end
end
