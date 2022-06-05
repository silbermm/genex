defmodule Genex.MixProject do
  use Mix.Project

  def project do
    [
      app: :genex,
      version: "0.0.1",
      elixir: "~> 1.13",
      escript: escript(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp escript do
    [main_module: Genex.CLI, strip_beams: [keep: ["Docs"]]]
  end

  def application do
    [
      extra_applications: [:logger, :iex]
    ]
  end

  defp deps do
    [
      {:diceware, "~> 0.2.8"},
      {:prompt, path: "../prompt"},
      {:ratatouille, "~> 0.5"},
      {:toml, "~> 0.6.2"},
      {:gpgmex, github: "silbermm/gpgmex", submodules: true},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
