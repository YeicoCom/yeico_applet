defmodule Applet.Alias do
  defmacro __using__(_) do
    quote do
      alias Applet.Multiple
      alias Applet.Dynamic
      alias Applet.Runner
      alias Applet.Unique
      alias Applet.Store
      alias Applet.Utils
      alias Applet.Dets
    end
  end
end
