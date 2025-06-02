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

  defp log(type, msg) do
    name = call(:name)
    Bus.broadcast!(:logger, {name, type, msg})
    Bus.broadcast!({:logger, name, type}, msg)
  end

  defp call(args), do: apply(Process.get(:__app__), [args])
end
