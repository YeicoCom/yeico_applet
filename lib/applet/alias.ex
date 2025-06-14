defmodule Applet.Alias do
  defmacro __using__(_) do
    quote do
      alias Applet.Multiple
      alias Applet.Dynamic
      alias Applet.Runner
      alias Applet.Unique
      alias Applet.Shared
      alias Applet.Pubsub
      alias Applet.Server
      alias Applet.Store
      alias Applet.Utils
      alias Applet.Dets
      alias Applet.Tasks
      alias Applet.Start
      alias Applet.Alias

      require Logger
    end
  end
end
