defmodule Applet.Runner do
  use Applet.Alias
  use Applet.Api

  def start_link(route, code, argv) do
    state = %{route: route, code: code, argv: argv}
    {:ok, spawn_link(fn -> init(state) end)}
  end

  defp init(%{route: route, code: code, argv: argv}) do
    :ok = Applet.stop!(route)
    Unique.register!({:applet, route}, nil)
    Multiple.register!(:applet, route)
    start = {Task.Supervisor, :start_link, []}
    spec = %{id: {route, :tasks}, start: start, restart: :temporary}
    {:ok, tasks} = Dynamic.start_child(spec)

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

    Api.info("Applet starting #{route}")
    {result, binding} = Api.evals(route, code, argv: argv)
    Unique.update!({:applet, route}, {result, binding})
    :timer.sleep(:infinity)
  end
end
