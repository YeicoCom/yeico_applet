defmodule Applet.Runner do
  use Applet.Alias
  use Applet.Api

  def start_link(name, code) do
    state = %{name: name, code: code}
    {:ok, spawn_link(fn -> init(state) end)}
  end

  defp init(%{name: name, code: code}) do
    Applet.stop!(name)
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
            fun.()
          end)
      end

    Process.put(:__app__, app)

    eval = fn ->
      {result, bindings} = Code.eval_string(code, [], file: "APPLET:#{name}")
      {result, bindings |> Enum.into(%{})}
    end

    result = Utils.run_safe(eval)
    Unique.update!({:applet, name}, result)
    :timer.sleep(:infinity)
  end
end
