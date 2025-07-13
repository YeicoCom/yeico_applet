defmodule AppletAsyncBusTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  test "async/bus applet" do
    code = """
    use Applet.Api
    Bus.subscribe!(:event, :sargs)
    Api.async(fn -> Bus.broadcast!(:event, :bargs) end)
    receive do
      {:event, :sargs, :bargs} -> Adb.put(:done, true)
    end
    """

    Run.applet(code, fn _ ->
      Wait.success(fn -> assert true == Adb.get(:done) end)
    end)
  end
end
