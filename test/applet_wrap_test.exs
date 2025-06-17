defmodule AppletWrapTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Applet.reset!()
    Adb.reset()
  end

  test "wrap fun/0" do
    route = "wrap"

    code = """
    use Applet.Api
    wrap1 = Api.wrap(fn -> raise "RAISE" end)
    Adb.put(:wrap1, Api.safe(wrap1))
    wrap2 = Api.wrap(fn -> throw "THROW" end)
    Adb.put(:wrap2, Api.safe(wrap2))
    wrap3 = Api.wrap(fn -> "OK" end)
    Adb.put(:wrap3, Api.safe(wrap3))
    """

    Applet.subscribe!(:trace, "wrap", nil)
    Applet.start!(route, code)
    Utils.wait_success(20, 20, fn -> assert {:error, %{type: :rescue}} = Adb.get(:wrap1) end)
    Utils.wait_success(20, 20, fn -> assert {:error, %{type: :catch}} = Adb.get(:wrap2) end)
    Utils.wait_success(20, 20, fn -> assert {:ok, "OK"} = Adb.get(:wrap3) end)
    assert_receive {{:logger, "wrap", :info}, nil, msg}
    assert msg == "Applet starting wrap"
    assert_receive {{:logger, "wrap", :debug}, nil, msg}
    assert msg =~ "UNHANDLED rescue error %RuntimeError"
    assert_receive {{:logger, "wrap", :trace}, nil, msg}
    assert msg =~ "UNHANDLED rescue stack"
    assert_receive {{:logger, "wrap", :debug}, nil, msg}
    assert msg =~ "UNHANDLED catch error"
    assert_receive {{:logger, "wrap", :trace}, nil, msg}
    assert msg =~ "UNHANDLED catch stack"
    Applet.stop!(route)
  end

  test "wrap fun/1" do
    route = "wrap"

    code = """
    use Applet.Api
    wrap1 = Api.wrap(fn arg -> raise arg end)
    Adb.put(:wrap1, Api.safe(wrap1, "RAISE"))
    wrap2 = Api.wrap(fn arg -> throw arg end)
    Adb.put(:wrap2, Api.safe(wrap2, "THROW"))
    wrap3 = Api.wrap(fn arg -> arg end)
    Adb.put(:wrap3, Api.safe(wrap3, "OK"))
    """

    Applet.subscribe!(:trace, "wrap", nil)
    Applet.start!(route, code)
    Utils.wait_success(20, 20, fn -> assert {:error, %{type: :rescue}} = Adb.get(:wrap1) end)
    Utils.wait_success(20, 20, fn -> assert {:error, %{type: :catch}} = Adb.get(:wrap2) end)
    Utils.wait_success(20, 20, fn -> assert {:ok, "OK"} = Adb.get(:wrap3) end)
    assert_receive {{:logger, "wrap", :info}, nil, msg}
    assert msg == "Applet starting wrap"
    assert_receive {{:logger, "wrap", :debug}, nil, msg}
    assert msg =~ "UNHANDLED rescue error %RuntimeError"
    assert_receive {{:logger, "wrap", :trace}, nil, msg}
    assert msg =~ "UNHANDLED rescue stack"
    assert_receive {{:logger, "wrap", :debug}, nil, msg}
    assert msg =~ "UNHANDLED catch error"
    assert_receive {{:logger, "wrap", :trace}, nil, msg}
    assert msg =~ "UNHANDLED catch stack"
    Applet.stop!(route)
  end
end
