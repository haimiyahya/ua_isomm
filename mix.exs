defmodule UaIsomm.MixProject do
  use Mix.Project

  def project do
    [
      app: :ua_isomm,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {UaIsomm.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:thousand_island, "~> 1.3"},
      {:ex_iso8583, git: "https://github.com/haimiyahya/ex_iso8583"}
    ]
  end
end
