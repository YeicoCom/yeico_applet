defmodule AppletEmptyTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Applet.reset!()
    Adb.reset()
  end

  test "empty applet" do
    route = "empty"
    code = ""

    {:ok, pid} = Applet.start!(route, code)
    Wait.success(fn -> assert [{^pid, ^route}] = Multiple.lookup(:applet) end)

    Wait.success(fn ->
      assert [{^pid, {nil, %{}}}] = Unique.lookup({:applet, route})
    end)

    Applet.stop!(route)
  end
end
