defmodule AppletDeferTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Utils.wait_success(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "defer applet" do
    name = "defer"

    code = """
    use Applet.Api

    Adb.put(:defer, 0)
    Api.async(fn -> Api.defer(fn -> Adb.put(:defer, 1) end) end)

    :ok
    """

    {:ok, pid} = Applet.start!(name, code)

    Utils.wait_success(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    Utils.wait_success(20, 20, fn ->
      assert [{^pid, {:ok, {:ok, %{}}}}] = Unique.lookup({:applet, name})
    end)

    Utils.wait_success(20, 20, fn -> assert 1 = Adb.get(:defer) end)

    :ok = Applet.stop!(name)
  end
end
