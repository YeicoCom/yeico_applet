defmodule Applet.Utils do
  use Applet.Alias

  def hostname(), do: :inet.gethostname() |> elem(1)

  def run_safe(fun) when is_function(fun, 0) do
    try do
      {:ok, fun.()}
    rescue
      error -> {:error, %{type: :rescue, error: error, stack: __STACKTRACE__}}
    catch
      error -> {:error, %{type: :catch, error: error, stack: __STACKTRACE__}}
    end
  end

  def kill_unique(key) do
    key
    |> Unique.lookup()
    |> Enum.each(&kill_pid(elem(&1, 0)))
  end

  def kill_multiple(key) do
    key
    |> Multiple.lookup()
    |> Enum.each(&kill_pid(elem(&1, 0)))
  end

  def kill_pid(pid) when is_pid(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)

    receive do
      {:DOWN, ^ref, _, ^pid, _} -> :ok
    end

    # not a reference
    # Process.demonitor(pid)
  end

  def wait_success(period, times, fun) when period > 0 and times > 0 and is_function(fun, 0) do
    last = times - 1

    Stream.interval(period)
    |> Stream.take(times)
    |> Stream.with_index()
    |> Stream.map(fn {_, i} -> {i, Utils.run_safe(fun)} end)
    |> Stream.take_while(fn
      {_, {:error, _}} -> true
      {_, {:ok, _}} -> false
    end)
    |> Stream.take(-1)
    |> Enum.to_list()
    |> case do
      [{^last, {:error, %{error: error, stack: stack}}}] -> reraise(error, stack)
      _ -> :ok
    end
  end

  def fmt(color, dt, type, msg) when is_binary(msg) do
    dt = NaiveDateTime.truncate(dt, :millisecond)

    [
      if(color, do: color, else: ""),
      NaiveDateTime.to_iso8601(dt),
      " ",
      type |> Atom.to_string() |> String.upcase(),
      " ",
      msg,
      if(color, do: IO.ANSI.reset(), else: ""),
      "\n"
    ]
  end

  def defer(fun) when is_function(fun, 0) do
    pid = self()

    # spawn to avoid sudden death
    spawn(fn ->
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, ^pid, _} -> run_safe(fun)
      end
    end)
  end
end
