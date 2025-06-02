defmodule Applet.Api do
  defmacro __using__(_) do
    quote do
      import Applet.Api, only: [sigil_H: 2]

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

  # https://elixirforum.com/t/can-liveview-ui-be-dynamically-loaded-using-h/47943/9#
  # https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_component.ex
  # use Phoenix.Component
  # expected %Phoenix.LiveView.Rendered{}

  alias Applet.Api.Bus

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

  defp log(type, msg) do
    name = call(:name)
    Bus.broadcast!(:logger, {name, type, msg})
    Bus.broadcast!({:logger, name, type}, msg)
  end

  defp call(args), do: apply(Process.get(:__app__), [args])
end
