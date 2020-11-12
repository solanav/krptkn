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
      extra_applications: [:appsignal, :logger, :observer],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # General
      {:gen_stage, "~> 1.0.0"},
      {:extractor, path: "extractor", tag: "v0.1.0"},

      # HTTP and HTML
      {:httpoison, "~> 1.6"},
      {:floki, "~> 0.29.0"},
      {:fast_html, "~> 2.0"},
      
      # Database
      {:mongodb, "~> 0.5.1"},
      {:postgrex, "~> 0.15.7"},
      {:jason, "~> 1.0"},

      # Development
      {:exprof, "~> 0.2.0"},

      # Metrics
      {:appsignal, "~> 1.0"},
    ]
  end
end
