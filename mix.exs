defmodule Applet.MixProject do
  use Mix.Project

  def project do
    [
      app: :applet,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Applet.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dns, "~> 2.4.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:modbus, github: "samuelventura/modbus", only: :test}
    ]
  end
end
