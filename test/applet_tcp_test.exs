defmodule Applet.TcpTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "tcp accept works on closed client" do
    {:ok, server} = Tcp.listen("127.0.0.1", 0)
    {:ok, client1} = Tcp.connect("127.0.0.1", server.port)
    :ok = Tcp.close(client1)
    {:ok, client2} = Tcp.accept(server)
    {:error, :closed} = Tcp.read(client2)
    :ok = Tcp.close(server)
    :ok = Tcp.close(client2)
  end

  test "tcp accept works on async" do
    {:ok, server} = Tcp.listen("127.0.0.1", 0)
    {:ok, client1} = Tcp.connect("127.0.0.1", server.port)
    {:ok, client2} = Task.async(fn -> Tcp.accept(server) end) |> Task.await()
    :ok = Tcp.close(server)
    :ok = Tcp.close(client1)
    :ok = Tcp.close(client2)
  end
end
