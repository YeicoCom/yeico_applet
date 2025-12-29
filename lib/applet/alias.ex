defmodule Applet.Alias do
  defmacro __using__(_) do
    quote do
      alias Applet.Multiple
      alias Applet.Dynamic
      alias Applet.Runner
      alias Applet.Unique
      alias Applet.Shared
      alias Applet.Store
      alias Applet.Utils
      alias Applet.Tasks
      alias Applet.Start
      alias Applet.Alias
      use Applet.Api

      require Logger
    end
  end
end
