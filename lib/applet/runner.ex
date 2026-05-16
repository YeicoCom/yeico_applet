defmodule Applet.Runner do
  use Applet.Alias

  def start_link(route, code, bindings) do
    state = %{route: route, code: code, bindings: bindings}
    {:ok, spawn_link(fn -> init(state) end)}
  end

  defp init(%{route: route, code: code, bindings: bindings}) do
    Process.flag(:trap_exit, true)
    :ok = Applet.stop!(route)
    Unique.register!({:applet_main, route}, nil)
    # for Applet.started
    Multiple.register!(:applet, route)
    spec = {Task.Supervisor, name: {:via, Registry, {Unique, {:applet_super, route}}}}
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

        {:async, tag, fun} ->
          # created task process gets linked to the caller
          # left as is to make unexpected exits very noticeable
          par = self()

          Task.Supervisor.async(tasks, fn ->
            Multiple.register!({:applet_task, route}, tag: tag, par: par)
            Process.put(:__tag__, tag)
            fun.()
          end)
      end

    Process.put(:__api__, api)
    Process.put(:__tag__, route)

    prefix = inspect(self())

    unless Applet.started?() do
      Logger.notice("#{prefix} Applet waiting: #{route}")
      Log.info("Applet waiting: #{route}")
      Applet.await()
    end

    Logger.notice("#{prefix} Applet starting: #{route}")
    Log.info("Applet starting: #{route}")
    Api.defer(fn -> Logger.notice("#{prefix} Applet exited: #{route}") end)
    Api.defer(fn -> Log.info("Applet exited: #{route}") end)
    {result, binding} = Api.evals(route, code, bindings)
    Unique.update!({:applet_main, route}, {result, binding})
    flush(self(), route)
  end

  defp flush(pid, route) do
    receive do
      msg ->
        Logger.notice(route: route, pid: pid, flush: msg)
        Log.debug(flush: msg)
        flush(pid, route)
    end
  end
end
