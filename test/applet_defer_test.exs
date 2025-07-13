defmodule AppletDeferTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  test "defer applet" do
    code = """
    use Applet.Api
    Api.async(fn -> Api.defer(fn -> Adb.put(:done, true) end) end)
    """

    Run.applet(code, fn _ ->
      Wait.success(fn -> assert true == Adb.get(:done) end)
    end)
  end
end
