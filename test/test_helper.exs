ExUnit.start()
Applet.start()

defmodule Wait do
  alias Applet.Utils

  def success(f) when is_function(f, 0) do
    Utils.wait_success(20, 20, f)
  end
end
