defmodule Applet.Api do
  defmacro __using__(_) do
    quote do
      alias Applet.Api.Bus
      alias Applet.Api.Adb
      alias Applet.Api.Ddb
      alias Applet.Api.Udb
      alias Applet.Api.Mdb
      alias Applet.Api.Tcp
      alias Applet.Api.Udp
      alias Applet.Api.Net
      alias Applet.Api.Ip4
      alias Applet.Api
    end
  end

  defmodule Live do
    defmacro sigil_H({:<<>>, meta, [expr]}, modifiers)
             when modifiers == [] or modifiers == ~c"noformat" do
      if not Macro.Env.has_var?(__CALLER__, {:assigns, nil}) do
        raise "~H requires a variable named \"assigns\" to exist and be set to a map"
      end

      caller =
        __CALLER__
        |> Map.put(:module, Applet.Script)
        |> Map.put(:function, {:render, 1})

      options = [
        engine: Phoenix.LiveView.TagEngine,
        file: caller.file,
        line: caller.line + 1,
        caller: caller,
        indentation: meta[:indentation] || 0,
        source: expr,
        tag_handler: Phoenix.LiveView.HTMLEngine
      ]

      EEx.compile_string(expr, options)
    end

    defmacro __using__(_) do
      quote do
        import Phoenix.Component, except: [sigil_H: 2]
        import Applet.Api.Live, only: [sigil_H: 2]
        alias Phoenix.LiveView.JS
        import Phoenix.LiveView
        import Phoenix.HTML
      end
    end
  end

  # https://elixirforum.com/t/can-liveview-ui-be-dynamically-loaded-using-h/47943/9#
  # https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_component.ex
  # https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view.ex
  # use Phoenix.Component
  # expected %Phoenix.LiveView.Rendered{}

  alias Applet.Utils
  alias Applet.Shared
  alias Applet.Api.Bus

  def route(), do: call(:route)
  def entry(), do: call(:entry)
  def path(), do: Applet.path()
  def load!(route), do: Applet.load!(route)
  def trace(msg), do: log(:trace, msg)
  def debug(msg), do: log(:debug, msg)
  def info(msg), do: log(:info, msg)
  def warn(msg), do: log(:warn, msg)
  def error(msg), do: log(:error, msg)
  def sleep(), do: :timer.sleep(:infinity)
  def sleep(millis), do: :timer.sleep(millis)
  def pid(%Task{pid: pid}), do: pid
  def file(), do: Path.basename(route())
  def name(), do: Path.basename(route(), ".exs")
  def hostname(), do: :inet.gethostname() |> elem(1) |> to_string()
  def relative(route), do: Path.join(Path.dirname(route()), route)
  def safe(fun) when is_function(fun, 0), do: Utils.run_safe(fun)
  def safe(fun, arg) when is_function(fun, 1), do: Utils.run_safe(fun, arg)
  def await(fun) when is_function(fun, 0), do: await(fun, 100)
  def await(task = %Task{}), do: call({:await, task, :infinity})
  def await(task = %Task{}, timeout), do: call({:await, task, timeout})

  def await(fun, poll) when is_function(fun, 0) do
    Stream.interval(poll)
    |> Stream.take_while(fn _ ->
      case Utils.run_safe(fun) do
        {:ok, true} -> false
        _ -> true
      end
    end)
    |> Stream.take(-1)
    |> Enum.to_list()
    |> is_list()
  end

  def query(), do: Shared.get("applets:query")
  def query(:hostname), do: Utils.hostname()
  def query(query), do: query().(query, [])
  def query(query, opts), do: query().(query, opts)
  def hook(hook), do: Shared.get("applets:hook:#{hook}")
  def hook(hook, args), do: apply(hook(hook), args)

  def async(fun) when is_function(fun, 0) do
    safe = wrap_safe(fun)
    call({:async, wrap_async(safe)})
  end

  def async(fun1, fun2) when is_function(fun1, 0) and is_function(fun2, 0) do
    safe1 = wrap_safe(fun1)
    safe2 = wrap_safe(fun2)
    call({:async, wrap_async(fn -> {safe1.(), safe2.()} end)})
  end

  def wrap(fun) when is_function(fun, 0) do
    safe = fn -> Utils.run_safe(fun) |> log_unhandled() |> unwrap_safe() end
    wrap_async(safe)
  end

  def wrap(fun) when is_function(fun, 1) do
    safe = fn arg -> Utils.run_safe(fun, arg) |> log_unhandled() |> unwrap_safe() end
    wrap_async(safe)
  end

  def defer(fun) when is_function(fun, 0) do
    safe = wrap_safe(fun)
    pid = self()

    entry = fn ->
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, ^pid, _} -> safe.()
      end
    end

    spawn(wrap_async(entry))
  end

  def post(topic, msg) do
    Bus.broadcast!({Bus, :post, topic}, msg)
  end

  def on(topic, fun) when is_function(fun, 1) do
    safe = wrap_safe(fun)

    loop = fn loop ->
      receive do
        {{Bus, :post, ^topic}, ^fun, msg} -> safe.(msg)
      end

      loop.(loop)
    end

    pid = self()

    init = fn ->
      Bus.subscribe!({Bus, :post, topic}, fun)
      send(pid, {Bus, :on, topic, fun})
      loop.(loop)
    end

    task = call({:async, wrap_async(init)})

    receive do
      {Bus, :on, ^topic, ^fun} -> task
    end
  end

  def evalf(route, binding \\ []) do
    code = Applet.load!(route)
    evals(route, code, binding)
  end

  def evals(route, code, binding \\ []) do
    {{result, binding}, diagnostics} =
      Code.with_diagnostics(fn ->
        api = Process.get(:__api__)

        unless route == route() do
          Process.put(:__api__, fn
            :route -> route
            other -> api.(other)
          end)
        end

        try do
          Code.eval_string(code, binding, file: route)
        rescue
          error -> {{error, __STACKTRACE__}, []}
        after
          Process.put(:__api__, api)
        end
      end)

    Enum.each(diagnostics, fn
      %{severity: :warning, position: p, message: m, file: f} -> warn("#{f}:#{p} #{m}")
      %{severity: :error, position: p, message: m, file: f} -> error("#{f}:#{p} #{m}")
    end)

    # too much error types to ensure full coverage
    case result do
      {%CompileError{file: f, line: p, description: m}, _} ->
        error("#{f}:#{p} #{m}")

      {ex = %{__exception__: true}, st} ->
        error("#{route}: #{inspect(ex)} #{inspect(st)}")

      result ->
        info("#{route}: #{inspect(result)}")
    end

    {result, binding |> Enum.into(%{})}
  end

  # log with entry route
  defp log(type, msg) when is_binary(msg) do
    entry = entry()
    Bus.broadcast!(:logger, {entry, type, msg})
    Bus.broadcast!({:logger, entry, type}, msg)
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
    fn -> Utils.run_safe(fun) |> log_unhandled() end
  end

  defp wrap_safe(fun) when is_function(fun, 1) do
    fn arg -> Utils.run_safe(fun, arg) |> log_unhandled() end
  end

  defp unwrap_safe({:ok, res}), do: res

  defp unwrap_safe({:error, %{type: :rescue, error: error, stack: stack}}) do
    reraise error, stack
  end

  defp unwrap_safe({:error, %{type: :catch, error: error, stack: _stack}}) do
    throw(error)
  end

  defp log_unhandled(res = {:error, %{type: type, error: error, stack: stack}}) do
    debug("UNHANDLED #{type} error #{inspect(error)}")
    trace("UNHANDLED #{type} stack #{inspect(stack)}")
    res
  end

  defp log_unhandled(res), do: res
end
