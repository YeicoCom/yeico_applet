defmodule Applet.Tasks do
  use Applet.Alias

  def start_link() do
    Task.Supervisor.start_link(name: __MODULE__)
  end

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  def async(fun) do
    Task.Supervisor.async(__MODULE__, fun)
  end

  def async(fun, clean) do
    Task.Supervisor.async(__MODULE__, fn ->
      Utils.run_safe(fun)
      Utils.run_safe(clean)
    end)
  end
end
