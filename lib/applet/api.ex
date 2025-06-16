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
      alias Applet.Api.Dns
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
  def safe(fun) when is_function(fun, 0), do: Utils.run_safe(fun)
  def safe(fun, arg) when is_function(fun, 1), do: Utils.run_safe(fun, arg)
  def await(task, timeout \\ :infinity), do: call({:await, task, timeout})

  def query(), do: Shared.get("applets:query")
  def query(:hostname), do: Utils.hostname()
  def query(query), do: query().(query, [])
  def query(query, opts), do: query().(query, opts)
  def hook(hook), do: Shared.get("applets:hook:#{hook}")
  def hook(hook, args), do: apply(hook(hook), args)

  def async(fun) when is_function(fun, 0) do
    safe = wrap_safe(fun)
    call({:async, wrap(safe)})
  end

  def async(fun1, fun2) when is_function(fun1, 0) and is_function(fun2, 0) do
    safe1 = wrap_safe(fun1)
    safe2 = wrap_safe(fun2)
    call({:async, wrap(fn -> {safe1.(), safe2.()} end)})
  end

  def wrap(fun) when is_function(fun, 0) do
    env = Process.get({:elixir, :eval_env})
    api = Process.get(:__api__)

    fn ->
      Process.put({:elixir, :eval_env}, env)
      Process.put(:__api__, api)
      fun.()
    end
  end

  def wrap(fun) when is_function(fun, 1) do
    env = Process.get({:elixir, :eval_env})
    api = Process.get(:__api__)

    fn arg ->
      Process.put({:elixir, :eval_env}, env)
      Process.put(:__api__, api)
      fun.(arg)
    end
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

    spawn(wrap(entry))
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

    task = call({:async, wrap(init)})

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
        try do
          Code.eval_string(code, binding, file: route)
        rescue
          error -> {{error, __STACKTRACE__}, []}
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

  defp log(type, msg) when is_binary(msg) do
    route = route()
    Bus.broadcast!(:logger, {route, type, msg})
    Bus.broadcast!({:logger, route, type}, msg)
    # for |> Api.trace()
    msg
  end

  defp log(type, msg) do
    log(type, inspect(msg))
    # for |> Api.trace()
    msg
  end

  defp call(args), do: apply(Process.get(:__api__), [args])

  defp wrap_safe(fun) when is_function(fun, 0) do
    fn -> Utils.run_safe(fun) |> unhandled() end
  end

  defp wrap_safe(fun) when is_function(fun, 1) do
    fn arg -> Utils.run_safe(fun, arg) |> unhandled() end
  end

  defp unhandled(res = {:error, %{type: type, error: error, stack: stack}}) do
    debug("UNHANDLED #{type} error #{inspect(error)}")
    trace("UNHANDLED #{type} stack #{inspect(stack)}")
    res
  end

  defp unhandled(res), do: res
end
