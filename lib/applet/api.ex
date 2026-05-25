defmodule Applet.Api do
  defmacro __using__(_) do
    quote do
      alias Applet.Api.Dets
      alias Applet.Api.Log
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
  alias Applet.Multiple
  alias Applet.Api.Bus
  alias Applet.Api.Adb
  alias Applet.Api.Log
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
  def receive(), do: receive(do: (msg -> msg))
  def safe(fun) when is_function(fun, 0), do: Utils.safe(fun)
  def safe(fun, arg) when is_function(fun, 1), do: Utils.safe(fun, arg)
  def swait(task = %Task{}), do: Utils.await(task)
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
    prev = Adb.replace(key, value)
    diff = prev != value
    if diff, do: Bus.broadcast!(key, value)
    diff
  end

  def loop(delay_ms, setup) when is_integer(delay_ms) and is_function(setup, 0) do
    fun = fn loop ->
      Process.flag(:trap_exit, true)
      async(setup) |> swait() |> Log.debug()
      flush(delay_ms)
      loop.(loop)
    end

    async(fun, fun)
  end

  def loop(delay_ms, setup, arg) when is_integer(delay_ms) and is_function(setup, 1) do
    fun = fn loop ->
      Process.flag(:trap_exit, true)
      async(setup, arg) |> swait() |> Log.debug()
      flush(delay_ms)
      loop.(loop)
    end

    async(fun, fun)
  end

  def loop(tag, delay_ms, setup)
      when is_binary(tag) and is_integer(delay_ms) and is_function(setup, 0) do
    fun = fn loop ->
      Process.flag(:trap_exit, true)
      async("#{tag}:setup", setup) |> swait() |> Log.debug()
      flush(delay_ms)
      loop.(loop)
    end

    async("#{tag}:super", fun, fun)
  end

  def loop(tag, delay_ms, setup, arg)
      when is_binary(tag) and is_integer(delay_ms) and is_function(setup, 1) do
    fun = fn loop ->
      Process.flag(:trap_exit, true)
      async("#{tag}:setup", setup, arg) |> swait() |> Log.debug()
      flush(delay_ms)
      loop.(loop)
    end

    async("#{tag}:super", fun, fun)
  end

  def flush(toms \\ 0) when is_integer(toms) do
    receive do
      msg ->
        Log.debug(flush: msg)
        flush(toms)
    after
      toms -> :ok
    end
  end

  def async(fun) when is_function(fun, 0) do
    safe = wrap_safe(fun)
    call({:async, nil, wrap_async(safe)})
  end

  def async(fun, arg) when is_function(fun, 1) do
    safe = wrap_safe(fn -> fun.(arg) end)
    call({:async, nil, wrap_async(safe)})
  end

  def async(tag, fun) when is_binary(tag) and is_function(fun, 0) do
    safe = wrap_safe(fun)
    call({:async, tag, wrap_async(safe)})
  end

  def async(tag, fun, arg) when is_binary(tag) and is_function(fun, 1) do
    safe = wrap_safe(fn -> fun.(arg) end)
    call({:async, tag, wrap_async(safe)})
  end

  def wrap(fun) when is_function(fun, 0) do
    safe = fn -> Utils.safe(fun) |> log_unhandled() |> unwrap_safe() end
    wrap_async(safe)
  end

  def wrap(fun) when is_function(fun, 1) do
    safe = fn arg -> Utils.safe(fun, arg) |> log_unhandled() |> unwrap_safe() end
    wrap_async(safe)
  end

  def defer(fun, arg) when is_function(fun, 1), do: defer(fn -> fun.(arg) end)

  def defer(fun) when is_function(fun, 0) do
    tag = Process.get(:__tag__)
    safe = wrap_safe(fun)
    pid = self()

    entry = fn ->
      Multiple.register!({:applet_defer, entry()}, tag: tag, pid: pid)
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, ^pid, _} -> safe.()
      end
    end

    spawn(wrap_async(entry))
  end

  def run(fun) when is_function(fun, 0) do
    safe = wrap_safe(fun)
    spawn(wrap_async(safe))
  end

  def evalf(route, bindings \\ []) do
    code = Applet.load!(route)
    evals(route, code, bindings)
  end

  def evals(route, code, bindings \\ []) do
    {{result, bindings}, diagnostics} =
      Code.with_diagnostics(fn ->
        %{api: api} = ctx = get_ctx()

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
          put_ctx(ctx)
        end
      end)

    # possition is row or {row, col}
    Enum.each(diagnostics, fn
      %{severity: :warning, position: p, message: m, file: f} ->
        Logger.warning(route: route, severity: :warning, position: p, message: m, file: f)
        Log.warn("#{f}:#{inspect(p)} compile warning #{m}")

      %{severity: :error, position: p, message: m, file: f} ->
        Logger.error(route: route, severity: :warning, position: p, message: m, file: f)
        Log.error("#{f}:#{inspect(p)} compile error #{m}")
    end)

    # too much error types to ensure full coverage
    case result do
      {:rescue, ex, st} ->
        Logger.error(route: route, rescue: ex, stack: st)
        Log.error("#{route} rescue: #{inspect(ex)} stack: #{inspect(st)}")

      {:catch, ex, st} ->
        Logger.error(route: route, catch: ex, stack: st)
        Log.error("#{route} catch: #{inspect(ex)} stack: #{inspect(st)}")

      result ->
        Logger.debug(route: route, result: result)
        Log.info("#{route}: #{inspect(result)}")
    end

    {result, bindings |> Enum.into(%{})}
  end

  # capture context for late wrapping
  def wrapper() do
    ctx = get_ctx()

    fn
      fun when is_function(fun, 0) ->
        fn ->
          ptx = get_ctx()
          put_ctx(ctx)

          try do
            fun.()
          after
            put_ctx(ptx)
          end
        end

      fun when is_function(fun, 1) ->
        fn arg ->
          ptx = get_ctx()
          put_ctx(ctx)

          try do
            fun.(arg)
          after
            put_ctx(ptx)
          end
        end
    end
  end

  # log with entry route
  def log(type, msg) when is_binary(msg) do
    line = "#{route()} #{inspect(self())} #{msg}"
    Applet.broadcast!(entry(), type, line)
    # for |> Log.trace()
    msg
  end

  def log(type, msg) do
    log(type, inspect(msg))
    # for |> Log.trace()
    msg
  end

  defp call(args), do: apply(Process.get(:__api__), [args])

  # https://elixirforum.com/t/how-to-keep-the-code-eval-string-environment-on-async-execution/71285
  defp get_ctx() do
    env = Process.get({:elixir, :eval_env})
    api = Process.get(:__api__)
    %{env: env, api: api}
  end

  defp put_ctx(%{env: env, api: api}) do
    Process.put({:elixir, :eval_env}, env)
    Process.put(:__api__, api)
  end

  defp wrap_async(fun) when is_function(fun, 0) do
    wrapper().(fun)
  end

  defp wrap_async(fun) when is_function(fun, 1) do
    wrapper().(fun)
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

  defp unwrap_safe({:error, %{type: :catch, error: error, stack: stack}}) do
    throw(%{error: error, stack: stack})
  end

  defp log_unhandled(res = {:error, %{type: type, error: error, stack: stack}}) do
    Logger.error(entry: entry(), route: route(), unhandled: type, error: error, stack: stack)
    Log.debug("UNHANDLED #{type} error #{inspect(error)}")
    Log.trace("UNHANDLED #{type} stack #{inspect(stack)}")
    res
  end

  defp log_unhandled(res), do: res
end
