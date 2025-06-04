defmodule AppletEvalTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  setup do
    Utils.wait_success(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "eval applet" do
    route = "test.exs"

    code = """
    use Applet.Api

    Api.evalf("\#{Api.name()}/\#{Api.file()}")
    """

    {:ok, pid} = Applet.start!(route, code)
    Utils.wait_success(20, 20, fn -> assert [{^pid, ^route}] = Multiple.lookup(:applet) end)

    Utils.wait_success(20, 20, fn ->
      assert [{^pid, {{:subscript, %{}}, %{}}}] = Unique.lookup({:applet, route})
    end)

    Applet.stop!(route)
  end
end
