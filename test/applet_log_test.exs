defmodule AppletLogTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  # check log works from sub applets
  # since sub applets now have their own route
  test "trace from evalf" do
    code = """
    use Applet.Api

    Api.evalf("test/log.exs")
    """

    port = Application.get_env(:applet, Server)[:port]

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "trace applet_test.exs\n")
    assert {:ok, "ok trace applet_test.exs\n"} = Tcp.read(client)

    Run.applet(code, fn _ ->
      line = Tcp.read(client) |> elem(1) |> String.trim()

      assert [_, "INFO", "Applet starting: applet_test.exs"] =
               String.split(line, " ", parts: 3, trim: true)

      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "TRACE", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "DEBUG", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "INFO", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "WARN", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
      :ok = Tcp.close(client)
    end)
  end

  test "applet trace" do
    code = """
    use Applet.Api

    Api.trace("msg")
    Api.debug("msg")
    Api.info("msg")
    Api.warn("msg")
    Api.error("msg")
    """

    port = Application.get_env(:applet, Server)[:port]

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "trace applet_test.exs\n")
    assert {:ok, "ok trace applet_test.exs\n"} = Tcp.read(client)

    Run.applet(code, fn _ ->
      line = Tcp.read(client) |> elem(1) |> String.trim()

      assert [_, "INFO", "Applet starting: applet_test.exs"] =
               String.split(line, " ", parts: 3, trim: true)

      line = Tcp.read(client) |> elem(1) |> String.trim() |> IO.inspect()
      assert [_, "TRACE", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "DEBUG", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "INFO", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "WARN", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
      :ok = Tcp.close(client)
    end)
  end

  test "applet debug" do
    code = """
    use Applet.Api

    Api.trace("msg")
    Api.debug("msg")
    Api.info("msg")
    Api.warn("msg")
    Api.error("msg")
    """

    port = Application.get_env(:applet, Server)[:port]

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "debug applet_test.exs\n")
    assert {:ok, "ok debug applet_test.exs\n"} = Tcp.read(client)

    Run.applet(code, fn _ ->
      line = Tcp.read(client) |> elem(1) |> String.trim()

      assert [_, "INFO", "Applet starting: applet_test.exs"] =
               String.split(line, " ", parts: 3, trim: true)

      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "DEBUG", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "INFO", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "WARN", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
      :ok = Tcp.close(client)
    end)
  end

  test "applet info" do
    code = """
    use Applet.Api

    Api.trace("msg")
    Api.debug("msg")
    Api.info("msg")
    Api.warn("msg")
    Api.error("msg")
    """

    port = Application.get_env(:applet, Server)[:port]

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "info applet_test.exs\n")
    assert {:ok, "ok info applet_test.exs\n"} = Tcp.read(client)

    Run.applet(code, fn _ ->
      line = Tcp.read(client) |> elem(1) |> String.trim()

      assert [_, "INFO", "Applet starting: applet_test.exs"] =
               String.split(line, " ", parts: 3, trim: true)

      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "INFO", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "WARN", "msg"] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [_, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
      :ok = Tcp.close(client)
    end)
  end

  test "applet localtime" do
    code = """
    use Applet.Api

    Api.error("msg")
    """

    port = Application.get_env(:applet, Server)[:port]

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    # check both work, with space and with T
    :ok = Tcp.write(client, "localtime 2000-01-01 00:00:00\n")
    assert {:ok, "ok localtime 2000-01-01 00:00:00\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "localtime 2000-01-01T00:00:00\n")
    assert {:ok, "ok localtime 2000-01-01T00:00:00\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "info applet_test.exs\n")
    assert {:ok, "ok info applet_test.exs\n"} = Tcp.read(client)

    Run.applet(code, fn _ ->
      line = Tcp.read(client) |> elem(1) |> String.trim()

      assert ["2000" <> _, "INFO", "Applet starting: applet_test.exs"] =
               String.split(line, " ", parts: 3, trim: true)

      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert ["2000" <> _, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
      :ok = Tcp.close(client)
    end)
  end

  test "applet ansicolor" do
    code = """
    use Applet.Api

    Api.trace("msg")
    Api.debug("msg")
    Api.info("msg")
    Api.warn("msg")
    Api.error("msg")
    """

    port = Application.get_env(:applet, Server)[:port]

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "ansicolor true\n")
    assert {:ok, "ok ansicolor true\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "trace applet_test.exs\n")
    assert {:ok, "ok trace applet_test.exs\n"} = Tcp.read(client)

    Run.applet(code, fn _ ->
      line = Tcp.read(client) |> elem(1) |> String.trim()

      trace = IO.ANSI.light_black()
      debug = IO.ANSI.light_cyan()
      info = IO.ANSI.blue()
      warn = IO.ANSI.yellow()
      error = IO.ANSI.light_red()
      reset = IO.ANSI.reset()

      assert [^info <> _, "INFO", "Applet starting: applet_test.exs" <> ^reset] =
               String.split(line, " ", parts: 3, trim: true)

      line = Tcp.read(client) |> elem(1) |> String.trim()

      assert [^trace <> _, "TRACE", "msg" <> ^reset] =
               String.split(line, " ", parts: 3, trim: true)

      line = Tcp.read(client) |> elem(1) |> String.trim()

      assert [^debug <> _, "DEBUG", "msg" <> ^reset] =
               String.split(line, " ", parts: 3, trim: true)

      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [^info <> _, "INFO", "msg" <> ^reset] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()
      assert [^warn <> _, "WARN", "msg" <> ^reset] = String.split(line, " ", parts: 3, trim: true)
      line = Tcp.read(client) |> elem(1) |> String.trim()

      assert [^error <> _, "ERROR", "msg" <> ^reset] =
               String.split(line, " ", parts: 3, trim: true)

      :ok = Tcp.close(client)
    end)
  end
end
