defmodule Applet.Runner do
  use Applet.Alias

  def start_link(route, code, bindings) do
    state = %{route: route, code: code, bindings: bindings}
    {:ok, spawn_link(fn -> init(state) end)}
  end

  defp init(%{route: route, code: code, bindings: bindings}) do
    :ok = Applet.stop!(route)
    Unique.register!({:applet, route}, nil)
    Multiple.register!(:applet, route)
    spec = {Task.Supervisor, name: {:via, Registry, {Unique, {:tasks, route}}}}
    {:ok, tasks} = Dynamic.start_child(spec)
    # terminate_child deletes spec for temporary children
    Utils.defer(fn -> Dynamic.terminate_child(tasks) end)

    api =
      fn
        :entry ->
          route

        :route ->
          route

        {:await, task, toms} ->
          Task.await(task, toms)

        {:async, fun} ->
          Task.Supervisor.async(tasks, fn ->
            Multiple.register!({:applet, route}, :async)
            fun.()
          end)
      end

    Process.put(:__api__, api)

    unless Applet.started?() do
      Api.info("Applet waiting #{route}")
      Applet.await()
    end

    Api.info("Applet starting: #{route}")
    Api.defer(fn -> Api.info("Applet exited: #{route}") end)
    {result, binding} = Api.evals(route, code, bindings)
    Unique.update!({:applet, route}, {result, binding})
    Process.sleep(:infinity)
  end
end
