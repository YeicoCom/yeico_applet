defmodule AppletServerTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Store.delete_all()

    Multiple.lookup(:applet)
    |> Enum.each(fn {_, n} -> :ok = Applet.stop!(n) end)

    Utils.wait_success(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "applet server test/test.exs" do
    port = Application.get_env(:applet, Server)[:port]
    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, "ok list saved\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok list started\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "save test/test.exs\n")
    assert {:ok, "ok save test/test.exs\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, ">test/test.exs\n"} = Tcp.read(client)
    assert {:ok, "ok list saved\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok list started\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "start test/test.exs\n")
    assert {:ok, "ok start test/test.exs\n"} = Tcp.read(client)

    Utils.wait_success(20, 20, fn ->
      assert [{_, "test/test.exs"}] = Multiple.lookup(:applet)
    end)

    :ok = Tcp.write(client, "list started\n")
    assert {:ok, ">test/test.exs\n"} = Tcp.read(client)
    assert {:ok, "ok list started\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "stop test/test.exs\n")
    assert {:ok, "ok stop test/test.exs\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok list started\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "delete test/test.exs\n")
    assert {:ok, "ok delete test/test.exs\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, "ok list saved\n"} = Tcp.read(client)
    :ok = Tcp.close(client)
  end

  test "applet server test.exs" do
    port = Application.get_env(:applet, Server)[:port]
    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, "ok list saved\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok list started\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "save test.exs\n")
    assert {:ok, "ok save test.exs\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, ">test.exs\n"} = Tcp.read(client)
    assert {:ok, "ok list saved\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok list started\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "start test.exs\n")
    assert {:ok, "ok start test.exs\n"} = Tcp.read(client)

    Utils.wait_success(20, 20, fn ->
      assert [{_, "test.exs"}] = Multiple.lookup(:applet)
    end)

    :ok = Tcp.write(client, "list started\n")
    assert {:ok, ">test.exs\n"} = Tcp.read(client)
    assert {:ok, "ok list started\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "stop test.exs\n")
    assert {:ok, "ok stop test.exs\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok list started\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "delete test.exs\n")
    assert {:ok, "ok delete test.exs\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, "ok list saved\n"} = Tcp.read(client)
    :ok = Tcp.close(client)
  end
end
