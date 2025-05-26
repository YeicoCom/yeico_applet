defmodule Applet.Api do
  defmacro __using__(_) do
    quote do
      alias Applet.Api.Sup
      alias Applet.Api.Bus
      # agent db
      alias Applet.Api.Adb
      # dets db
      alias Applet.Api.Ddb
    end
  end
end
