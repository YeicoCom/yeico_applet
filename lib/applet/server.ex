defmodule Applet.Server do
  use Applet.Alias
  use Applet.Api

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, opts}
    }
  end

  def start_link(opts \\ []) do
    port = Keyword.get(opts, :port, 3999)
    task = SuperTasks.async(Tasks, fn -> init(port) end)
    {:ok, Api.pid(task)}
  end

  def init(port) do
    true = Process.register(self(), __MODULE__)

    Store.list()
    |> Enum.each(fn {n, d} -> Applet.start!(n, d) end)

    {:ok, server} = Tcp.listen("127.0.0.1", port, line: true)
    Logger.info("Applet Server \#{server.port}")
    accept(server)
  end

  defp accept(server) do
    {:ok, client} = Tcp.accept(server)
    Logger.info("Applet Client \#{client.port}")
    task = SuperTasks.async(Tasks, fn -> serve(client) end)
    :ok = Tcp.owner(client, Api.pid(task))
    accept(server)
  end

  defp serve(client) do
    case Tcp.read(client) do
      {:ok, "save " <> path} ->
        path = String.trim(path)
        {name, data} = Applet.load!(path)
        :ok = Store.upsert(name, data)

      {:ok, "delete " <> name} ->
        name = String.trim(name)
        :ok = Store.delete(name)

      {:ok, "start " <> name} ->
        name = String.trim(name)
        [{^name, data}] = Store.lookup(name)
        Applet.start!(name, data)

      {:ok, "stop " <> name} ->
        name = String.trim(name)
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
