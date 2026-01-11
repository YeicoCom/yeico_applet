defmodule Applet.UdpActiveTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "udp/active applet" do
    Bus.subscribe!(:port)

    serve = fn loop, server ->
      case Udp.receive(server) do
        {:error, error} ->
          {:error, error}

        {:ok, {ip, port, data}} ->
          :ok = Udp.write(server, ip, port, data)
          loop.(loop, server)
      end
    end

    Task.async(fn ->
      {:ok, server} = Udp.listen("127.0.0.1", 0, active: true)
      Bus.broadcast!(:port, server.port)
      task = Task.async(fn -> serve.(serve, server) end)
      :ok = Udp.owner(server, task)
    end)

    port =
      receive do
        {:port, nil, port} -> port
      end

    {:ok, client} = Udp.connect("127.0.0.1", port)
    :ok = Udp.write(client, "ping\n")
    {:ok, {_, _, "ping\n"}} = Udp.read(client)
    :ok = Udp.close(client)

    {:ok, client} = Udp.connect({127, 0, 0, 1}, port)
    :ok = Udp.write(client, "ping\n")
    {:ok, {_, _, "ping\n"}} = Udp.read(client)
    :ok = Udp.close(client)
  end
end
