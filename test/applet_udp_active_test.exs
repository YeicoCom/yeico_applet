defmodule AppletUdpActiveTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  import Eventually

  setup do
    eventually(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "udp/active applet" do
    name = "udp/active"

    code = """
    use Applet.Api

    Bus.subscribe!(:port)

    Api.async(fn ->
      serve = fn loop, server ->
        case Udp.receive(server) do
          {:error, error} ->
            Api.debug("Udp Echo Server \#{server.port}: \#{error}")
            {:error, error}

          {:ok, {ip, port, data}} ->
            Api.debug("Udp Echo Client \#{port}: \#{data}")
            :ok = Udp.write(server, ip, port, data)
            loop.(loop, server)
        end
      end

      {:ok, server} = Udp.listen("127.0.0.1", 0, active: true)
      Api.info("Udp Echo Server \#{server.port}")
      Bus.broadcast!(:port, server.port)
      task = Api.async(fn -> serve.(serve, server) end)
      :ok = Udp.owner(server, Api.pid(task))
    end)

    port = receive do
      {:port, nil, port} -> port
    end

    {:ok, client} = Udp.connect("127.0.0.1", port)
    :ok = Udp.write(client, "ping\n")
    {:ok, {_, _, "ping\n"}} = Udp.read(client)
    :ok = Udp.close(client)
    """

    {:ok, pid} = Applet.start!(name, code)

    eventually(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    eventually(20, 20, fn ->
      assert [{^pid, {:ok, {:ok, %{}}}}] = Unique.lookup({:applet, name})
    end)

    :ok = Applet.stop!(name)
  end
end
