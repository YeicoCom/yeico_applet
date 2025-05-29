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

  test "applet server" do
    port = Application.get_env(:applet, Server)[:port]
    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    File.write!("/tmp/yeico_applet_server_test.exs", ":ok")
    :ok = Tcp.write(client, "save /tmp/yeico_applet_server_test.exs\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, ">yeico_applet_server_test\n"} = Tcp.read(client)
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "start yeico_applet_server_test\n")
    assert {:ok, "ok\n"} = Tcp.read(client)

    Utils.wait_success(20, 20, fn ->
      assert [{_, "yeico_applet_server_test"}] = Multiple.lookup(:applet)
    end)

    :ok = Tcp.write(client, "list started\n")
    assert {:ok, ">yeico_applet_server_test\n"} = Tcp.read(client)
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "stop yeico_applet_server_test\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "delete yeico_applet_server_test\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.close(client)
  end
end
