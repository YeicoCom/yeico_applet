defmodule AppletEvalTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  test "evals result" do
    code = """
    use Applet.Api
    r = Api.evals("test.exs", "a=1; 2")
    Adb.put(:result, r)
    Adb.put(:done, true)
    """

    Run.applet(code, fn _ ->
      Wait.success(fn -> assert true == Adb.get(:done) end)
      assert {2, %{a: 1}} == Adb.get(:result)
    end)
  end

  test "evals environ" do
    code = """
    use Applet.Api
    Adb.put(:route1, Api.route())
    Api.evals("evals/test.exs", "use Applet.Api; Adb.put(:route2, Api.route())")
    Adb.put(:route3, Api.route())
    """

    Run.applet(code, fn %{route: route} ->
      Wait.success(fn -> assert route == Adb.get(:route1) end)
      Wait.success(fn -> assert "evals/test.exs" == Adb.get(:route2) end)
      Wait.success(fn -> assert route == Adb.get(:route3) end)
    end)
  end

  test "evalf applet" do
    code = """
    use Applet.Api
    Api.evalf("test/done.exs")
    """

    Run.applet(code, fn _ ->
      Wait.success(fn -> assert true == Adb.get(:done) end)
    end)
  end
end
