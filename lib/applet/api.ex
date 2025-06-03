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
  alias Applet.Api.Bus

  def name(), do: call(:name)
  def wait(), do: Applet.wait()
  def trace(msg), do: log(:trace, msg)
  def debug(msg), do: log(:debug, msg)
  def info(msg), do: log(:info, msg)
  def warn(msg), do: log(:warn, msg)
  def error(msg), do: log(:error, msg)
  def sleep(), do: :timer.sleep(:infinity)
  def sleep(millis), do: :timer.sleep(millis)
  def pid(%Task{pid: pid}), do: pid
  def await(task, timeout \\ :infinity), do: call({:await, task, timeout})

  def async(fun) when is_function(fun, 0), do: call({:async, fun})

  def async(fun1, fun2) when is_function(fun1, 0) and is_function(fun2, 0),
    do: call({:async, fun1, fun2})

  def wrap(fun) when is_function(fun, 1) do
    api = Process.get(:__api__)

    fn arg ->
      Process.put(:__api__, api)
      fun.(arg)
    end
  end

  def defer(fun) when is_function(fun, 0) do
    api = Process.get(:__api__)
    pid = self()

    spawn(fn ->
      Process.put(:__api__, api)
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, ^pid, _} -> :ok
      end

      Utils.run_safe(fun)
    end)
  end

  def post(topic, msg) do
    Bus.broadcast!({Bus, :post, topic}, msg)
  end

  def on(topic, fun) when is_function(fun, 1) do
    loop = fn loop ->
      msg =
        receive do
          {{Bus, :post, ^topic}, ^fun, msg} -> msg
        end

      Utils.run_safe(fn -> fun.(msg) end)

      loop.(loop)
    end

    pid = self()

    wrap = fn ->
      Bus.subscribe!({Bus, :post, topic}, fun)
      send(pid, {Bus, :on, topic, fun})
      loop.(loop)
    end

    task = async(wrap)

    receive do
      {Bus, :on, ^topic, ^fun} -> task
    end
  end

  defp log(type, msg) do
    name = call(:name)
    Bus.broadcast!(:logger, {name, type, msg})
    Bus.broadcast!({:logger, name, type}, msg)
  end

  defp call(args), do: apply(Process.get(:__api__), [args])
end
