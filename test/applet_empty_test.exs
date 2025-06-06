defmodule AppletEmptyTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  setup do
    Applet.reset!()
  end

  test "empty applet" do
    route = "empty"
    code = ""

    {:ok, pid} = Applet.start!(route, code)
    Utils.wait_success(20, 20, fn -> assert [{^pid, ^route}] = Multiple.lookup(:applet) end)

    Utils.wait_success(20, 20, fn ->
      assert [{^pid, {nil, %{}}}] = Unique.lookup({:applet, route})
    end)

    Applet.stop!(route)
  end
end
