defmodule Applet.Api do
  defmacro __using__(_) do
    quote do
      alias Applet.Api
      alias Applet.Api.Bus
      alias Applet.Api.Adb
      alias Applet.Api.Ddb
      alias Applet.Api.Udb
      alias Applet.Api.Mdb
    end
  end

  def async(fun) when is_function(fun, 0), do: call({:async, fun})
  def await(task, timeout \\ 5_000), do: call({:await, task, timeout})
  defp call(args), do: apply(Process.get(:__app__), [args])
end
