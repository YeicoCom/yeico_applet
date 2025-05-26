defmodule Applet.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Applet.Multiple,
      Applet.Dynamic,
      Applet.Unique,
      Applet.Store,
      Applet.Api.Bus,
      Applet.Api.Ddb,
      Applet.Api.Adb,
      Applet.Api.Mdb,
      Applet.Api.Udb
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Applet.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
