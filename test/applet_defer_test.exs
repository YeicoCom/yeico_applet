defmodule AppletDeferTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Applet.reset!()
    Adb.reset()
  end

  test "defer applet" do
    route = "defer"

    code = """
    use Applet.Api

    Adb.put(:defer, 0)
    Api.async(fn -> Api.defer(fn -> Adb.put(:defer, 1) end) end)

    :ok
    """

    Applet.start!(route, code)
    Utils.wait_success(20, 20, fn -> assert 1 = Adb.get(:defer) end)
    Applet.stop!(route)
  end
end
