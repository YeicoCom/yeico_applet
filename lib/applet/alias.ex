defmodule Applet.Alias do
  defmacro __using__(_) do
    quote do
      alias Applet.Runner
      alias Applet.Dynamic
    end
  end
end
