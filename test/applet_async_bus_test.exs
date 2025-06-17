defmodule AppletAsyncBusTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Applet.reset!()
    Adb.reset()
  end

  test "async/bus applet" do
    route = "async/bus"

    code = """
    use Applet.Api

    Api.async(fn ->
      Bus.subscribe!(:event, :sargs)
      Api.async(fn ->
        Bus.broadcast!(:event, :bargs)
        Api.sleep()
      end)
      receive do
        {:event, :sargs, :bargs} -> :ok
      end
    end) |> Api.await()

    Applet.Unique.register!(:test, \"#{route}\")
    """

    Applet.start!(route, code)
    Utils.wait_success(20, 20, fn -> assert [{_, ^route}] = Unique.lookup(:test) end)
    Applet.stop!(route)
  end
end
