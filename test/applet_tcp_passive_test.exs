defmodule AppletTcpPassiveTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  setup do
    Utils.wait_success(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "tcp/passive applet" do
    name = "tcp/passive"

    code = """
    use Applet.Api

    Bus.subscribe!(:port)
    Bus.subscribe!(:closed)

    Api.async(fn ->
      serve = fn loop, client ->
        case Tcp.read(client) do
          {:error, :closed} ->
            Api.debug("Tcp Echo Client \#{client.port}: closed")
            Bus.broadcast!(:closed, client)
            :closed

          {:ok, data} ->
            Api.debug("Tcp Echo Client \#{client.port}: \#{data}")
            :ok = Tcp.write(client, data)
            loop.(loop, client)
        end
      end

      accept = fn loop, server ->
        {:ok, client} = Tcp.accept(server)
        Api.info("Tcp Echo Client \#{client.port}")
        task = Api.async(fn -> serve.(serve, client) end)
        :ok = Tcp.owner(client, Api.pid(task))
        loop.(loop, server)
      end

      {:ok, server} = Tcp.listen("127.0.0.1", 0, line: true)
      Api.info("Tcp Echo Server \#{server.port}")
      Bus.broadcast!(:port, server.port)
      accept.(accept, server)
    end)

    port = receive do
      {:port, nil, port} -> port
    end

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "ping\n")
    {:ok, "ping\n"} = Tcp.read(client)
    :ok = Tcp.close(client)

    receive do
      {:closed, nil, %{}} -> :closed
    end
    """

    {:ok, pid} = Applet.start!(name, code)

    Utils.wait_success(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    Utils.wait_success(20, 20, fn ->
      assert [{^pid, {:ok, {:closed, %{}}}}] = Unique.lookup({:applet, name})
    end)

    :ok = Applet.stop!(name)
  end
end
