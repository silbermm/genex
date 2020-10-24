defmodule GenexCli.MixProject do
  use Mix.Project

  @app :genex

  def project do
    [
      app: @app,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      escript: escript(),
      releases: [{@app, release()}]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :public_key],
      mod: {Genex.Application, []}
    ]
  end

  def release() do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      steps: [:assemble, &Bakeware.assemble/1],
      strip_beams: Mix.env() == :prod
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"},
      {:diceware, "~> 0.2.5"},
      {:prompt, "~> 0.1.5"},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:bakeware, path: "../bakeware/bakeware", runtime: false}
    ]
  end

  defp escript do
    [main_module: Genex.CLI]
  end
end
