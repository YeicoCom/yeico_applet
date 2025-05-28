defmodule Applet.Server do
  use Applet.Alias
  use Applet.Api

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  def start_link() do
    config = Application.get_env(:applet, __MODULE__)
    port = config[:port]
    task = Tasks.async(fn -> init(port) end)
    {:ok, Api.pid(task)}
  end

  defp init(port) do
    true = Process.register(self(), __MODULE__)

    Store.list()
    |> Enum.each(fn {n, d} ->
      Logger.notice("Applet auto start #{n}")
      Applet.start!(n, d)
    end)

    {:ok, server} = Tcp.listen("127.0.0.1", port, line: true)
    Logger.notice("Applet Server port #{server.port}")
    accept(server)
  end

  defp accept(server) do
    {:ok, client} = Tcp.accept(server)
    run = fn -> serve(client) end
    clean = fn -> :ok = Tcp.close(client) end
    %Task{} = Tasks.async(run, clean)
    accept(server)
  end

  defp serve(client) do
    case Tcp.read(client) do
      {:ok, "save " <> path} ->
        path = String.trim(path)
        Logger.notice("Applet client #{client.port} save #{path}")
        {name, data} = Applet.load!(path)
        :ok = Store.upsert(name, data)

      {:ok, "delete " <> name} ->
        name = String.trim(name)
        Logger.notice("Applet client #{client.port} delete #{name}")
        :ok = Store.delete(name)

      {:ok, "start " <> name} ->
        name = String.trim(name)
        Logger.notice("Applet client #{client.port} start #{name}")
        [{^name, data}] = Store.lookup(name)
        {:ok, _pid} = Applet.start!(name, data)

      {:ok, "stop " <> name} ->
        name = String.trim(name)
        Logger.notice("Applet client #{client.port} stop #{name}")
        :ok = Applet.stop!(name)

      {:ok, "list saved\n"} ->
        Store.keys()
        |> Enum.each(fn n -> :ok = Tcp.write(client, ">#{n}\n") end)

      {:ok, "list started\n"} ->
        Multiple.lookup(:applet)
        |> Enum.each(fn {_, n} -> :ok = Tcp.write(client, ">#{n}\n") end)
    end

    :ok = Tcp.write(client, "ok\n")
    serve(client)
  end
end
