defmodule AppletAdbTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Applet.reset!()
    Adb.reset()
  end

  test "adb" do
    route = "adb.exs"

    code = """
    use Applet.Api
    Adb.put(:a, "a")
    Adb.put(:b, Adb.get())
    Adb.update(fn m -> Map.put(m, :c, "c") end)
    Adb.update(:d, "d", fn _ -> "D" end)
    Adb.update(:e, "e", fn _ -> "E" end)
    Adb.update(:e, "e", fn _ -> "E" end)
    """

    Applet.start!(route, code)
    Wait.success(fn -> assert "a" == Adb.get(:a) end)
    Wait.success(fn -> assert %{a: "a"} == Adb.get(:b) end)
    Wait.success(fn -> assert "c" == Adb.get(:c) end)
    Wait.success(fn -> assert "d" == Adb.get(:d) end)
    Wait.success(fn -> assert "E" == Adb.get(:e) end)
    Adb.reset()
    assert %{} == Adb.get()
    Applet.stop!(route)
  end
end
