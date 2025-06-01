defmodule Applet.Runner do
  use Applet.Alias
  use Applet.Api

  def start_link(name, code) do
    state = %{name: name, code: code}
    {:ok, spawn_link(fn -> init(state) end)}
  end

  defp init(%{name: name, code: code}) do
    :ok = Applet.stop!(name)
    Unique.register!({:applet, name}, nil)
    Multiple.register!(:applet, name)
    start = {Task.Supervisor, :start_link, []}
    spec = %{id: {name, :tasks}, start: start, restart: :temporary}
    {:ok, tasks} = Dynamic.start_child(spec)

    app =
      fn
        :name ->
          name

        {:await, task, timeout} ->
          Task.await(task, timeout)

        {:async, fun} ->
          app = Process.get(:__app__)

          Task.Supervisor.async(tasks, fn ->
            Multiple.register!({:applet, name}, :async)
            Process.put(:__app__, app)
            Utils.run_safe(fun)
          end)

        {:async, fun1, fun2} ->
          app = Process.get(:__app__)

          Task.Supervisor.async(tasks, fn ->
            Multiple.register!({:applet, name}, :async)
            Process.put(:__app__, app)
            res1 = Utils.run_safe(fun1)
            res2 = Utils.run_safe(fun2)
            {res1, res2}
          end)
      end

    Process.put(:__app__, app)
    Api.info("APPLET STARTING #{name}")

    eval = fn ->
      {result, bindings} = Code.eval_string(code, [], file: "APPLET:#{name}")
      {result, bindings |> Enum.into(%{})}
    end

    result = Utils.run_safe(eval)
    Unique.update!({:applet, name}, result)

    case result do
      {:ok, res} -> Api.info("APPLET EVAL RESULT #{inspect(res)}")
      {:error, res} -> Api.error("APPLET EVAL RESULT #{inspect(res)}")
    end

    :timer.sleep(:infinity)
  end
end
