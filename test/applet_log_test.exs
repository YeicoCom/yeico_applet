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
    :ok = Tcp.write(client, "timezone America/Mexico_City\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "trace trace\n")
    {:ok, _pid} = Applet.start!(name, code)
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

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "trace trace\n")
    {:ok, _pid} = Applet.start!(name, code)
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
    :ok = Tcp.write(client, "timezone America/Mexico_City\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "debug debug\n")
    {:ok, _pid} = Applet.start!(name, code)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "DEBUG", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "INFO", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "WARN", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
    :ok = Tcp.close(client)

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "debug debug\n")
    {:ok, _pid} = Applet.start!(name, code)
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
    :ok = Tcp.write(client, "timezone America/Mexico_City\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "info info\n")
    {:ok, _pid} = Applet.start!(name, code)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "INFO", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "WARN", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
    :ok = Tcp.close(client)

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "info info\n")
    {:ok, _pid} = Applet.start!(name, code)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "INFO", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "WARN", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
    :ok = Tcp.close(client)
  end
end
