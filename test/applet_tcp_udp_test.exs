defmodule AppletTcpUdpTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Applet.reset!()
    Adb.reset()
  end

  test "tcp listen and connect error" do
    {:ok, socket} = Tcp.listen("127.0.0.1", 0)
    {:error, _} = Tcp.listen("127.0.0.1", socket.port)
    :ok = Tcp.close(socket)
    {:error, _} = Tcp.connect("127.0.0.1", socket.port)
  end

  test "udp connect error" do
    {:ok, socket} = Udp.listen("127.0.0.1", 0)
    {:error, _} = Udp.listen("127.0.0.1", socket.port)
    {:ok, socket} = Udp.connect("127.0.0.1", 8000)
    {:error, _} = Udp.listen("127.0.0.1", socket.port)
  end
end
