defmodule AppletLogTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Store.delete_all()

    Multiple.lookup(:applet)
    |> Enum.each(fn {_, n} -> :ok = Applet.stop!(n) end)

    Utils.wait_success(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "applet trace" do
    name = "trace"

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
    :ok = Tcp.write(client, "trace trace\n")
    {:ok, _pid} = Applet.start!(name, code)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "INFO", "APPLET STARTING trace"] = String.split(line, " ", parts: 3, trim: true)
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
  end

  test "applet debug" do
    name = "debug"

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
    :ok = Tcp.write(client, "debug debug\n")
    {:ok, _pid} = Applet.start!(name, code)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "INFO", "APPLET STARTING debug"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "DEBUG", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "INFO", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "WARN", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
    :ok = Tcp.close(client)
  end

  test "applet info" do
    name = "info"

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
    :ok = Tcp.write(client, "info info\n")
    {:ok, _pid} = Applet.start!(name, code)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "INFO", "APPLET STARTING info"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "INFO", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "WARN", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
    :ok = Tcp.close(client)
  end

  test "applet localtime" do
    name = "localtime"

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
    :ok = Tcp.write(client, "info localtime\n")
    {:ok, _pid} = Applet.start!(name, code)
    line = Tcp.read(client) |> elem(1) |> String.trim()

    assert ["2000" <> _, "INFO", "APPLET STARTING localtime"] =
             String.split(line, " ", parts: 3, trim: true)

    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert ["2000" <> _, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
    :ok = Tcp.close(client)
  end

  test "applet ansicolor" do
    name = "ansicolor"

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
    :ok = Tcp.write(client, "trace ansicolor\n")
    {:ok, _pid} = Applet.start!(name, code)
    line = Tcp.read(client) |> elem(1) |> String.trim()

    trace = IO.ANSI.light_black()
    debug = IO.ANSI.blue()
    info = IO.ANSI.light_cyan()
    warn = IO.ANSI.yellow()
    error = IO.ANSI.light_red()
    reset = IO.ANSI.reset()

    assert [^info <> _, "INFO", "APPLET STARTING ansicolor" <> ^reset] =
             String.split(line, " ", parts: 3, trim: true)

    line = Tcp.read(client) |> elem(1) |> String.trim()

    assert [^trace <> _, "TRACE", "msg" <> ^reset] =
             String.split(line, " ", parts: 3, trim: true)

    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [^debug <> _, "DEBUG", "msg" <> ^reset] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [^info <> _, "INFO", "msg" <> ^reset] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [^warn <> _, "WARN", "msg" <> ^reset] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [^error <> _, "ERROR", "msg" <> ^reset] = String.split(line, " ", parts: 3, trim: true)
    :ok = Tcp.close(client)
  end
end
