defmodule AppletEvalTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Applet.reset!()
    Adb.reset()
  end

  test "eval applet" do
    route = "test.exs"

    code = """
    use Applet.Api

    Api.evalf("\#{Api.name()}/\#{Api.file()}")
    """

    {:ok, pid} = Applet.start!(route, code)
    Wait.success(fn -> assert [{^pid, ^route}] = Multiple.lookup(:applet) end)

    Wait.success(fn ->
      assert [{^pid, {{:subscript, %{}}, %{}}}] = Unique.lookup({:applet, route})
    end)

    Applet.stop!(route)
  end
end
