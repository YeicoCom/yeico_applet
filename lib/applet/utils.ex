defmodule Applet.Utils do
  use Applet.Alias

  def pid(%Task{pid: pid}), do: pid

  def sleep(), do: Process.sleep(:infinity)

  def sleep(millis), do: Process.sleep(millis)

  def hostname() do
    {:ok, host} = :inet.gethostname()
    to_string(host)
  end

  def hostname_f() do
    {hostname, 0} = System.cmd("hostname", ["-f"])
    hostname |> String.trim()
  end

  def resolve(host) do
    with {:ok, {a, b, c, d}} <- :inet.getaddr(~c"#{host}", :inet) do
      {:ok, "#{a}.#{b}.#{c}.#{d}"}
    end
  end

  def defer(fun), do: defer(self(), fun)

  def defer(pid, fun) when is_pid(pid) and is_function(fun, 0) do
    # spawn to avoid sudden death
    spawn(fn ->
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, ^pid, _} -> safe(fun)
      end
    end)
  end

  def safe(fun) when is_function(fun, 0) do
    try do
      {:ok, fun.()}
    rescue
      error -> {:error, %{type: :rescue, error: error, stack: __STACKTRACE__}}
    catch
      error -> {:error, %{type: :catch, error: error, stack: __STACKTRACE__}}
    end
  end

  def safe(fun, arg) when is_function(fun, 1) do
    try do
      {:ok, fun.(arg)}
    rescue
      error -> {:error, %{type: :rescue, error: error, stack: __STACKTRACE__}}
    catch
      error -> {:error, %{type: :catch, error: error, stack: __STACKTRACE__}}
    end
  end

  def kill(%Task{pid: pid}), do: kill(pid)

  def kill(pid) when is_pid(pid) do
    Process.unlink(pid)
    Process.exit(pid, :kill)
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, _, ^pid, _} -> :ok
    end

    # not a reference
    # Process.demonitor(pid)
  end
end
