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
    Task.Supervisor.async(__MODULE__, fn ->
      Utils.safe(fun)
    end)
  end

  def async(fun1, fun2) do
    Task.Supervisor.async(__MODULE__, fn ->
      res1 = Utils.safe(fun1)
      res2 = Utils.safe(fun2)
      {res1, res2}
    end)
  end
end
