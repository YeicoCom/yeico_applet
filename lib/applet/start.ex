defmodule Applet.Start do
  use Applet.Alias

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  def start_link() do
    {:ok, spawn_link(&init/0)}
  end

  defp init() do
    true = Process.register(self(), __MODULE__)
    Shared.put("applets:path", Applet.path())
    Shared.put("applets:started", true)
    :timer.sleep(:infinity)
  end
end
