defmodule Applet.Api do
  defmacro __using__(_) do
    quote do
      alias Applet.Bus
      # agent db
      alias Applet.Adb
      # dets db
      alias Applet.Ddb
    end
  end
end
