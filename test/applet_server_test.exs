defmodule AppletServerTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api
  import Eventually

  setup do
    Store.delete_all()

    Multiple.lookup(:applet)
    |> Enum.each(fn {_, n} -> :ok = Applet.stop!(n) end)

    eventually(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "applet server" do
    {:ok, client} = Tcp.connect("127.0.0.1", 3999, line: true)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    File.write!("/tmp/yeico_applet_server_test.exs", ":ok")
    :ok = Tcp.write(client, "save /tmp/yeico_applet_server_test.exs\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, ">yeico_applet_server_test.exs\n"} = Tcp.read(client)
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "start yeico_applet_server_test.exs\n")
    assert {:ok, "ok\n"} = Tcp.read(client)

    eventually(20, 20, fn ->
      assert [{_, "yeico_applet_server_test.exs"}] = Multiple.lookup(:applet)
    end)

    :ok = Tcp.write(client, "list started\n")
    assert {:ok, ">yeico_applet_server_test.exs\n"} = Tcp.read(client)
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "stop yeico_applet_server_test.exs\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list started\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "delete yeico_applet_server_test.exs\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.write(client, "list saved\n")
    assert {:ok, "ok\n"} = Tcp.read(client)
    :ok = Tcp.close(client)
  end
end
