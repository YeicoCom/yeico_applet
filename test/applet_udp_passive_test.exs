defmodule AppletUdpPassiveTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  test "udp/passive applet" do
    code = """
    use Applet.Api

    Bus.subscribe!(:port)

    Api.async(fn ->
      serve = fn loop, server ->
        case Udp.read(server) do
          {:error, error} ->
            Api.debug("Udp Echo Server \#{server.port}: \#{error}")
            {:error, error}

          {:ok, {ip, port, data}} ->
            Api.debug("Udp Echo Client \#{port}: \#{data}")
            :ok = Udp.write(server, ip, port, data)
            loop.(loop, server)
        end
      end

      {:ok, server} = Udp.listen("127.0.0.1", 0)
      Api.info("Udp Echo Server \#{server.port}")
      Bus.broadcast!(:port, server.port)
      serve.(serve, server)
    end)

    port = receive do
      {:port, nil, port} -> port
    end

    {:ok, client} = Udp.connect("127.0.0.1", port)
    :ok = Udp.write(client, "ping\n")
    {:ok, {_, _, "ping\n"}} = Udp.read(client)
    :ok = Udp.close(client)
    """

    Run.applet(code, fn %{pid: pid, route: route} ->
      Wait.success(fn ->
        assert [{^pid, {:ok, %{}}}] = Unique.lookup({:applet, route})
      end)
    end)
  end
end
