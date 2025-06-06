defmodule AppletServerTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Applet.reset!()
  end

  test "applet server test/test.exs" do
    port = Application.get_env(:applet, Server)[:port]
    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "list stored\n")
    assert {:ok, "ok list stored\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok list started\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "install test/test.exs\n")
    assert {:ok, "ok install test/test.exs\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list stored\n")
    assert {:ok, ">test/test.exs\n"} = Tcp.read(client)
    assert {:ok, "ok list stored\n"} = Tcp.read(client)

    Utils.wait_success(20, 20, fn ->
      assert [{_, "test/test.exs"}] = Multiple.lookup(:applet)
    end)

    :ok = Tcp.write(client, "list started\n")
    assert {:ok, ">test/test.exs\n"} = Tcp.read(client)
    assert {:ok, "ok list started\n"} = Tcp.read(client)
  end

  test "applet server test.exs" do
    port = Application.get_env(:applet, Server)[:port]
    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "list stored\n")
    assert {:ok, "ok list stored\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok list started\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "install test.exs\n")
    assert {:ok, "ok install test.exs\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list stored\n")
    assert {:ok, ">test.exs\n"} = Tcp.read(client)
    assert {:ok, "ok list stored\n"} = Tcp.read(client)

    Utils.wait_success(20, 20, fn ->
      assert [{_, "test.exs"}] = Multiple.lookup(:applet)
    end)

    :ok = Tcp.write(client, "list started\n")
    assert {:ok, ">test.exs\n"} = Tcp.read(client)
    assert {:ok, "ok list started\n"} = Tcp.read(client)
    :ok = Tcp.close(client)
  end

  test "applet server reboot" do
    :ok = Store.upsert("test.exs", ":ok")
    :ok = Store.upsert("test/test.exs", ":ok")
    {:ok, _} = Applet.start!("test.exs")
    port = Application.get_env(:applet, Server)[:port]
    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "reboot\n")
    assert {:ok, "ok reboot\n"} = Tcp.read(client)
    :ok = Tcp.close(client)

    Utils.wait_success(20, 20, fn ->
      assert 2 = Multiple.lookup(:applet) |> length()
    end)
  end

  test "applet server restart" do
    :ok = Store.upsert("test.exs", ":ok")
    :ok = Store.upsert("test/test.exs", ":ok")
    {:ok, pid1} = Applet.start!("test.exs")
    port = Application.get_env(:applet, Server)[:port]
    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "restart\n")
    assert {:ok, "ok restart\n"} = Tcp.read(client)
    :ok = Tcp.close(client)

    Utils.wait_success(20, 20, fn ->
      with [{pid2, _}] <- Multiple.lookup(:applet) do
        refute pid1 == pid2
      else
        _ -> raise "Empty"
      end
    end)

    Utils.wait_success(20, 20, fn ->
      assert 1 = Multiple.lookup(:applet) |> length()
    end)
  end

  test "applet server reset" do
    :ok = Store.upsert("test.exs", ":ok")
    :ok = Store.upsert("test/test.exs", ":ok")
    {:ok, _} = Applet.start!("test.exs")
    port = Application.get_env(:applet, Server)[:port]
    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "reset\n")
    assert {:ok, "ok reset\n"} = Tcp.read(client)
    :ok = Tcp.close(client)
    assert [] = Applet.started()
    assert [] = Applet.stored()
  end
end
