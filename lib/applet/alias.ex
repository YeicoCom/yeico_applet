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
      alias Applet.Bus
      alias Applet.Pdb
      alias Applet.Tdb
    end
  end
end
