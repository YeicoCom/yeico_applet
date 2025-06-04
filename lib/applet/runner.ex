defmodule Applet.Runner do
  use Applet.Alias
  use Applet.Api

  def start_link(route, code) do
    state = %{route: route, code: code}
    {:ok, spawn_link(fn -> init(state) end)}
  end

  defp init(%{route: route, code: code}) do
    :ok = Applet.stop!(route)
    Unique.register!({:applet, route}, nil)
    Multiple.register!(:applet, route)
    start = {Task.Supervisor, :start_link, []}
    spec = %{id: {route, :tasks}, start: start, restart: :temporary}
    {:ok, tasks} = Dynamic.start_child(spec)

    api =
      fn
        :route ->
          route

        {:await, task, timeout} ->
          Task.await(task, timeout)

        {:async, fun} ->
          api = Process.get(:__api__)

          Task.Supervisor.async(tasks, fn ->
            Multiple.register!({:applet, route}, :async)
            Process.put(:__api__, api)
            Utils.run_safe(fun)
          end)

        {:async, fun1, fun2} ->
          api = Process.get(:__api__)

          Task.Supervisor.async(tasks, fn ->
            Multiple.register!({:applet, route}, :async)
            Process.put(:__api__, api)
            res1 = Utils.run_safe(fun1)
            res2 = Utils.run_safe(fun2)
            {res1, res2}
          end)
      end

    Process.put(:__api__, api)

    unless Applet.started?() do
      Api.info("Applet waiting #{route}")
      Applet.await()
    end

    Api.info("Applet starting #{route}")
    {result, binding} = Api.evals(route, code)
    Unique.update!({:applet, route}, {result, binding})
    :timer.sleep(:infinity)
  end
end
