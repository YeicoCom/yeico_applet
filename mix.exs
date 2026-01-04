defmodule Applet.MixProject do
  use Mix.Project

  def project do
    [
      app: :applet,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      test_ignore_filters: [&String.starts_with?(&1, "test/applets/")],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Applet.Application, []}
    ]
  end

  # https://elixirforum.com/t/clarification-on-dets-nerves-issue-mentioned-at-elixirconf/10145
  defp deps do
    [
      {:cubdb, "2.0.2"}
    ]
  end
end
