defmodule AppletTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  import Eventually

  setup do
    eventually(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "empty applet" do
    name = "empty"
    code = ""

    {:ok, pid} = Applet.start!(name, code)

    eventually(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    eventually(20, 20, fn ->
      assert [{^pid, {:ok, {nil, %{}}}}] = Unique.lookup({:applet, name})
    end)

    :ok = Applet.stop!(name)
  end

  test "async/bus applet" do
    name = "async/bus"

    code = """
    use Applet.Api

    Api.async(fn ->
      Bus.subscribe!(:event, :sargs)
      Api.async(fn ->
        Bus.broadcast!(:event, :bargs)
        Api.sleep()
      end)
      receive do
        {:event, :sargs, :bargs} -> :ok
      end
    end) |> Api.await()
    """

    {:ok, pid} = Applet.start!(name, code)

    eventually(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    eventually(20, 20, fn ->
      assert [{^pid, {:ok, {:ok, %{}}}}] = Unique.lookup({:applet, name})
    end)

    :ok = Applet.stop!(name)
  end

  test "tcp applet" do
    name = "tcp"

    code = """
    use Applet.Api

    Bus.subscribe!(:port)

    Api.async(fn ->
      serve = fn loop, client ->
        case Tcp.read(client) do
          {:error, :closed} ->
            Api.debug("Tcp Echo Client \#{client.port}: closed")
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

      {:ok, server} = Tcp.listen({127, 0, 0, 1}, 0, line: true)
      Api.info("Tcp Echo Server \#{server.port}")
      Bus.broadcast!(:port, server.port)
      accept.(accept, server)
    end)

    port = receive do
      {:port, nil, port} -> port
    end

    {:ok, client} = Tcp.connect({127, 0, 0, 1}, port, line: true)
    :ok = Tcp.write(client, "ping\n")
    {:ok, "ping\n"} = Tcp.read(client)
    """

    {:ok, pid} = Applet.start!(name, code)

    eventually(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    eventually(20, 20, fn ->
      assert [{^pid, {:ok, {{:ok, "ping\n"}, %{}}}}] = Unique.lookup({:applet, name})
    end)

    :ok = Applet.stop!(name)
  end

  test "modbus applet" do
    name = "modbus"

    code = """
    # run with: mix slave
    alias Modbus.Slave
    alias Modbus.Master

    # start your slave with a shared model
    model = %{
      0x50 => %{
        {:c, 0x5152} => 0,
        {:i, 0x5354} => 0,
        {:i, 0x5355} => 1,
        {:hr, 0x5657} => 0x6162,
        {:ir, 0x5859} => 0x6364,
        {:ir, 0x585A} => 0x6566
      }
    }

    {:ok, slave} = Slave.start_link(model: model)
    # get the assigned tcp port
    port = Slave.port(slave)

    # interact with it
    {:ok, master} = Master.start_link(ip: {127, 0, 0, 1}, port: port)

    # read input
    {:ok, [0, 1]} = Master.exec(master, {:ri, 0x50, 0x5354, 2})
    # read input registers
    {:ok, [0x6364, 0x6566]} = Master.exec(master, {:rir, 0x50, 0x5859, 2})

    # toggle coil and read it back
    :ok = Master.exec(master, {:fc, 0x50, 0x5152, 0})
    {:ok, [0]} = Master.exec(master, {:rc, 0x50, 0x5152, 1})
    :ok = Master.exec(master, {:fc, 0x50, 0x5152, 1})
    {:ok, [1]} = Master.exec(master, {:rc, 0x50, 0x5152, 1})

    # increment holding register and read it back
    {:ok, [0x6162]} = Master.exec(master, {:rhr, 0x50, 0x5657, 1})
    :ok = Master.exec(master, {:phr, 0x50, 0x5657, 0x6163})
    {:ok, [0x6163]} = Master.exec(master, {:rhr, 0x50, 0x5657, 1})

    :ok = Master.stop(master)
    :ok = Slave.stop(slave)
    """

    {:ok, pid} = Applet.start!(name, code)

    eventually(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    eventually(20, 20, fn ->
      assert [{^pid, {:ok, {:ok, %{slave: _, port: _, model: _, master: _}}}}] =
               Unique.lookup({:applet, name})
    end)

    :ok = Applet.stop!(name)
  end
end
