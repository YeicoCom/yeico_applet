defmodule Applet.Api do
  defmacro __using__(_) do
    quote do
      alias Applet.Api.Dets
      alias Applet.Api.Bus
      alias Applet.Api.Adb
      alias Applet.Api.Udb
      alias Applet.Api.Mdb
      alias Applet.Api.Tcp
      alias Applet.Api.Udp
      alias Applet.Api.Net
      alias Applet.Api.Ip4
      alias Applet.Api
      require Logger
    end
  end

  alias Applet.Utils
  alias Applet.Api.Bus
  alias Applet.Api.Adb
  require Logger

  def route(), do: call(:route)
  def entry(), do: call(:entry)
  def path(), do: Applet.path()
  def path(route), do: Applet.path(route)
  def load!(route), do: Applet.load!(route)
  def trace(msg), do: log(:trace, msg)
  def debug(msg), do: log(:debug, msg)
  def info(msg), do: log(:info, msg)
  def warn(msg), do: log(:warn, msg)
  def error(msg), do: log(:error, msg)
  def sleep(), do: Utils.sleep()
  def sleep(millis), do: Utils.sleep(millis)
  def pid(%Task{} = task), do: Utils.pid(task)
  def kill(pid) when is_pid(pid), do: Utils.kill(pid)
  def kill(%Task{pid: pid}) when is_pid(pid), do: Utils.kill(pid)
  def hostname(), do: Utils.hostname()
  def hostname_f(), do: Utils.hostname_f()
  def resolve(host), do: Utils.resolve(host)
  def safe(fun) when is_function(fun, 0), do: Utils.safe(fun)
  def safe(fun, arg) when is_function(fun, 1), do: Utils.safe(fun, arg)
  def await(fun) when is_function(fun, 0), do: await(fun, 100)
  def await(task = %Task{}), do: call({:await, task, :infinity})
  def await(task = %Task{}, toms), do: call({:await, task, toms})

  def await(fun, poll) when is_function(fun, 0) do
    Stream.interval(poll)
    |> Stream.take_while(fn _ ->
      case Utils.safe(fun) do
        {:ok, true} -> false
        _ -> true
      end
    end)
    |> Stream.take(-1)
    |> Enum.to_list()
    |> is_list()
  end

  def subget!(key, opts \\ []) do
    Bus.subscribe!(key, Keyword.get(opts, :sarg))
    Adb.get(key, Keyword.get(opts, :defv))
  end

  def putcast!(key, value) do
    Adb.put(key, value)
    Bus.broadcast!(key, value)
  end

  def async(fun) when is_function(fun, 0) do
    safe = wrap_safe(fun)
    call({:async, wrap_async(safe)})
  end

  def async(fun, arg) when is_function(fun, 1) do
    safe = wrap_safe(fn -> fun.(arg) end)
    call({:async, wrap_async(safe)})
  end

  def async(fun1, fun2) when is_function(fun1, 0) and is_function(fun2, 0) do
    safe1 = wrap_safe(fun1)
    safe2 = wrap_safe(fun2)
    call({:async, wrap_async(fn -> {safe1.(), safe2.()} end)})
  end

  def wrap(fun) when is_function(fun, 0) do
    safe = fn -> Utils.safe(fun) |> log_unhandled() |> unwrap_safe() end
    wrap_async(safe)
  end

  def wrap(fun) when is_function(fun, 1) do
    safe = fn arg -> Utils.safe(fun, arg) |> log_unhandled() |> unwrap_safe() end
    wrap_async(safe)
  end

  def defer(fun), do: defer(self(), fun)

  def defer(pid, fun) when is_pid(pid) and is_function(fun, 0) do
    safe = wrap_safe(fun)

    entry = fn ->
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, ^pid, _} -> safe.()
      end
    end

    spawn(wrap_async(entry))
  end

  def evalf(route, bindings \\ []) do
    code = Applet.load!(route)
    evals(route, code, bindings)
  end

  def evals(route, code, bindings \\ []) do
    {{result, bindings}, diagnostics} =
      Code.with_diagnostics(fn ->
        api = Process.get(:__api__)

        unless route == route() do
          Process.put(:__api__, fn
            :route -> route
            other -> api.(other)
          end)
        end

        # return is either the try or the rescue block
        # resulting expression in efter block is ignored
        try do
          Code.eval_string(code, bindings, file: route)
        rescue
          error -> {{:rescue, error, __STACKTRACE__}, []}
        catch
          error -> {{:catch, error, __STACKTRACE__}, []}
        after
          Process.put(:__api__, api)
        end
      end)

    # possition is row or {row, col}
    Enum.each(diagnostics, fn
      %{severity: :warning, position: p, message: m, file: f} ->
        Logger.warning(route: route, severity: :warning, position: p, message: m, file: f)
        warn("#{f}:#{inspect(p)} compile warning #{m}")
      %{severity: :error, position: p, message: m, file: f} ->
        Logger.error(route: route, severity: :warning, position: p, message: m, file: f)
        error("#{f}:#{inspect(p)} compile error #{m}")
    end)

    # too much error types to ensure full coverage
    case result do
      {:rescue, ex, st} ->
        Logger.error(route: route, rescue: ex, stack: st)
        error("#{route}: #{inspect(ex)} #{inspect(st)}")

      {:catch, ex, st} ->
        Logger.error(route: route, catch: ex, stack: st)
        error("#{route}: #{inspect(ex)} #{inspect(st)}")

      result ->
        Logger.debug(route: route, result: result)
        info("#{route}: #{inspect(result)}")
    end

    {result, bindings |> Enum.into(%{})}
  end

  # log with entry route
  defp log(type, msg) when is_binary(msg) do
    Applet.broadcast!(entry(), type, msg)
    # for |> Api.trace()
    msg
  end

  defp log(type, msg) do
    log(type, inspect(msg))
    # for |> Api.trace()
    msg
  end

  defp call(args), do: apply(Process.get(:__api__), [args])

  defp wrap_async(fun) when is_function(fun, 0) do
    env = Process.get({:elixir, :eval_env})
    api = Process.get(:__api__)

    fn ->
      Process.put({:elixir, :eval_env}, env)
      Process.put(:__api__, api)
      fun.()
    end
  end

  defp wrap_async(fun) when is_function(fun, 1) do
    env = Process.get({:elixir, :eval_env})
    api = Process.get(:__api__)

    fn arg ->
      Process.put({:elixir, :eval_env}, env)
      Process.put(:__api__, api)
      fun.(arg)
    end
  end

  defp wrap_safe(fun) when is_function(fun, 0) do
    fn -> Utils.safe(fun) |> log_unhandled() end
  end

  defp wrap_safe(fun) when is_function(fun, 1) do
    fn arg -> Utils.safe(fun, arg) |> log_unhandled() end
  end

  defp unwrap_safe({:ok, res}), do: res

  defp unwrap_safe({:error, %{type: :rescue, error: error, stack: stack}}) do
    reraise error, stack
  end

  defp unwrap_safe({:error, %{type: :catch, error: error, stack: _stack}}) do
    throw(error)
  end

  defp log_unhandled(res = {:error, %{type: type, error: error, stack: stack}}) do
    Logger.error(entry: entry(), route: route(), unhandled: type, error: error, stack: stack)
    debug("UNHANDLED #{type} error #{inspect(error)}")
    trace("UNHANDLED #{type} stack #{inspect(stack)}")
    res
  end

  defp log_unhandled(res), do: res
end
