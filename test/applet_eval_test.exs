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

  test "evalf compile error with r" do
    code = """
    use Applet.Api
    Api.evalf("test/compile1.exs")
    """

    port = Application.get_env(:applet, Server)[:port]

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "trace applet_test.exs\n")
    assert {:ok, "ok trace applet_test.exs\n"} = Tcp.read(client)

    Run.applet(code, fn _ ->
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "INFO", "Applet starting applet_test.exs"] =
               String.split(line, " ", parts: 3, trim: true)

      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "ERROR", msg] = String.split(line, " ", parts: 3, trim: true)
      assert msg =~ "test/compile1.exs:3 expected -> clauses for :else in"

      :ok = Tcp.close(client)
    end)
  end

  test "evalf compile warning with {r, c}" do
    code = """
    use Applet.Api
    Api.evalf("test/compile2.exs")
    """

    port = Application.get_env(:applet, Server)[:port]

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "trace applet_test.exs\n")
    assert {:ok, "ok trace applet_test.exs\n"} = Tcp.read(client)

    Run.applet(code, fn _ ->
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "INFO", "Applet starting applet_test.exs"] =
               String.split(line, " ", parts: 3, trim: true)

      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "WARN", "test/compile2.exs:{5, 13} trailing commas are not allowed inside function/macro call arguments"] =
               String.split(line, " ", parts: 3, trim: true)

      :ok = Tcp.close(client)
    end)
  end
end
