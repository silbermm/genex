defmodule Genex.MixProject do
  use Mix.Project

  def project do
    [
      app: :genex,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:jason, "~> 1.1"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false}
    ]
  end

  defp escript do
    [main_module: Genex.CLI]
  end
end
