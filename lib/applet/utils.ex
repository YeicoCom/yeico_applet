defmodule Applet.Utils do
  use Applet.Alias

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
end
