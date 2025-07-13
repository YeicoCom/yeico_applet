defmodule AppletRunLogTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Applet.reset!()
    Adb.reset()
  end

  test "applet run trace" do
    port = Application.get_env(:applet, Server)[:port]
    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "run trace test/log.exs\n")
    {:ok, "ok run trace test/log.exs\n"} = Tcp.read(client)
    line = Tcp.read(client) |> elem(1) |> String.trim()

    assert [_, "INFO", "Applet starting test/log.exs"] =
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
    :ok = Applet.await!("test/log.exs")
  end

  test "applet run debug" do
    port = Application.get_env(:applet, Server)[:port]

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "run debug test/log.exs\n")
    {:ok, "ok run debug test/log.exs\n"} = Tcp.read(client)
    line = Tcp.read(client) |> elem(1) |> String.trim()

    assert [_, "INFO", "Applet starting test/log.exs"] =
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
    :ok = Applet.await!("test/log.exs")
  end

  test "applet run info" do
    port = Application.get_env(:applet, Server)[:port]
    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "run info test/log.exs\n")
    {:ok, "ok run info test/log.exs\n"} = Tcp.read(client)
    line = Tcp.read(client) |> elem(1) |> String.trim()

    assert [_, "INFO", "Applet starting test/log.exs"] =
             String.split(line, " ", parts: 3, trim: true)

    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "INFO", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "WARN", "msg"] = String.split(line, " ", parts: 3, trim: true)
    line = Tcp.read(client) |> elem(1) |> String.trim()
    assert [_, "ERROR", "msg"] = String.split(line, " ", parts: 3, trim: true)
    :ok = Tcp.close(client)
    :ok = Applet.await!("test/log.exs")
  end
end
