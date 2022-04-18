defmodule ExunitJsonFormatter.MixProject do
  use Mix.Project

  def project do
    [
      app: :exunit_json_formatter,
      version: "0.1.0",
      elixir: "~> 1.13",
      description: description(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application, do: []

  defp description do
    """
    ExunitJsonFormatter provdes JSON-formatted output for ExUnit.
    """
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.3"}
    ]
  end

  defp package do
    [
      maintainers: ["Chris Ertel"],
      licenses: ["Public Domain (unlicense)", "WTFPL", "New BSD"],
      links: %{"GitHub" => "https://github.com/crertel/exunit_json_formatter"}
    ]
  end
end
