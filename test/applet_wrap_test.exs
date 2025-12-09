defmodule AppletWrapTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  test "wrap fun/0" do
    code = """
    use Applet.Api
    wrap1 = Api.wrap(fn -> raise "RAISE" end)
    Adb.put(:wrap1, Api.safe(wrap1))
    wrap2 = Api.wrap(fn -> throw "THROW" end)
    Adb.put(:wrap2, Api.safe(wrap2))
    wrap3 = Api.wrap(fn -> "OK" end)
    Adb.put(:wrap3, Api.safe(wrap3))
    """

    Applet.subscribe!(:trace, "applet_test.exs", nil)

    Run.applet(code, fn %{route: route} ->
      Wait.success(fn -> assert {:error, %{type: :rescue}} = Adb.get(:wrap1) end)
      Wait.success(fn -> assert {:error, %{type: :catch}} = Adb.get(:wrap2) end)
      Wait.success(fn -> assert {:ok, "OK"} = Adb.get(:wrap3) end)
      assert_receive {{:logger, ^route, :info}, nil, msg}
      assert msg == "Applet starting: applet_test.exs"
      assert_receive {{:logger, ^route, :debug}, nil, msg}
      assert msg =~ "UNHANDLED rescue error %RuntimeError"
      assert_receive {{:logger, ^route, :trace}, nil, msg}
      assert msg =~ "UNHANDLED rescue stack"
      assert_receive {{:logger, ^route, :debug}, nil, msg}
      assert msg =~ "UNHANDLED catch error"
      assert_receive {{:logger, ^route, :trace}, nil, msg}
      assert msg =~ "UNHANDLED catch stack"
    end)
  end

  test "wrap fun/1" do
    code = """
    use Applet.Api
    wrap1 = Api.wrap(fn arg -> raise arg end)
    Adb.put(:wrap1, Api.safe(wrap1, "RAISE"))
    wrap2 = Api.wrap(fn arg -> throw arg end)
    Adb.put(:wrap2, Api.safe(wrap2, "THROW"))
    wrap3 = Api.wrap(fn arg -> arg end)
    Adb.put(:wrap3, Api.safe(wrap3, "OK"))
    """

    Applet.subscribe!(:trace, "applet_test.exs", nil)

    Run.applet(code, fn %{route: route} ->
      Wait.success(fn -> assert {:error, %{type: :rescue}} = Adb.get(:wrap1) end)
      Wait.success(fn -> assert {:error, %{type: :catch}} = Adb.get(:wrap2) end)
      Wait.success(fn -> assert {:ok, "OK"} = Adb.get(:wrap3) end)
      assert_receive {{:logger, ^route, :info}, nil, msg}
      assert msg == "Applet starting: applet_test.exs"
      assert_receive {{:logger, ^route, :debug}, nil, msg}
      assert msg =~ "UNHANDLED rescue error %RuntimeError"
      assert_receive {{:logger, ^route, :trace}, nil, msg}
      assert msg =~ "UNHANDLED rescue stack"
      assert_receive {{:logger, ^route, :debug}, nil, msg}
      assert msg =~ "UNHANDLED catch error"
      assert_receive {{:logger, ^route, :trace}, nil, msg}
      assert msg =~ "UNHANDLED catch stack"
    end)
  end
end
