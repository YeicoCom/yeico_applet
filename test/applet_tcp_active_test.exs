defmodule Applet.TcpActiveTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "tcp/active applet" do
    Bus.subscribe!(:port)
    Bus.subscribe!(:closed)

    serve = fn loop, client ->
      case Tcp.receive(client) do
        {:error, :closed} ->
          Bus.broadcast!(:closed, client)
          :closed

        {:ok, data} ->
          :ok = Tcp.write(client, data)
          loop.(loop, client)
      end
    end

    accept = fn loop, server ->
      {:ok, client} = Tcp.accept(server)
      task = Task.async(fn -> serve.(serve, client) end)
      :ok = Tcp.owner(client, task)
      loop.(loop, server)
    end

    Task.async(fn ->
      {:ok, server} = Tcp.listen("127.0.0.1", 0, line: true, active: true)
      Bus.broadcast!(:port, server.port)
      accept.(accept, server)
    end)

    port =
      receive do
        {:port, nil, port} -> port
      end

    {:ok, client} = Tcp.connect("127.0.0.1", port, line: true)
    :ok = Tcp.write(client, "ping\n")
    {:ok, "ping\n"} = Tcp.read(client)
    :ok = Tcp.close(client)

    assert :closed ==
             (receive do
                {:closed, nil, %{}} -> :closed
              end)

    {:ok, client} = Tcp.connect({127, 0, 0, 1}, port, line: true)
    :ok = Tcp.write(client, "ping\n")
    {:ok, "ping\n"} = Tcp.read(client)
    :ok = Tcp.close(client)

    assert :closed ==
             (receive do
                {:closed, nil, %{}} -> :closed
              end)
  end
end
