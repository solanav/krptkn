defmodule Krptkn.MixProject do
  use Mix.Project

  def project do
    [
      app: :krptkn,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Krptkn.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gen_stage, "~> 1.0.0"},
      {:floki, "~> 0.29.0"},
      {:httpoison, "~> 1.6"},
      {:exprof, "~> 0.2.0"},
      {:html5ever, "~> 0.8.0"},
      {:mongodb, "~> 0.5.1"},
    ]
  end
end
