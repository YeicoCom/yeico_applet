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
    config = config()
    port = config[:port]
    colors = config[:colors]
    task = Tasks.async(fn -> init(port, colors) end)
    {:ok, Api.pid(task)}
  end

  def config() do
    config = Application.get_env(:applet, __MODULE__)
    %{port: config[:port], colors: config[:colors] |> Enum.into(%{})}
  end

  defp init(port, colors) do
    true = Process.register(self(), __MODULE__)

    Store.list()
    |> Enum.each(fn {n, d} ->
      Logger.notice("Applet auto start #{n}")
      Applet.start!(n, d)
    end)

    {:ok, server} = Tcp.listen("127.0.0.1", port, line: true)
    Logger.notice("Applet server port #{server.port}")
    accept(server, colors)
  end

  defp accept(server, colors) do
    {:ok, client} = Tcp.accept(server)
    fun1 = fn -> serve(client, %{colors: colors}) end
    fun2 = fn -> :ok = Tcp.close(client) end
    %Task{} = Tasks.async(fun1, fun2)
    accept(server, colors)
  end

  defp serve(client, state) do
    with {:ok, cmd} <- Tcp.read(client),
         state = %{} <- serve(client, state, cmd) do
      :ok = Tcp.write(client, ["ok ", cmd])
      serve(client, state)
    else
      unexpected ->
        Logger.notice("Applet client #{client.port} unexpected #{inspect(unexpected)}")
    end
  end

  defp serve(client, state, cmd) do
    case cmd do
      "install " <> route ->
        route = String.trim(route)
        Logger.notice("Applet client #{client.port} install #{route}")
        code = Applet.load!(route)
        :ok = Store.upsert(route, code)
        {:ok, _pid} = Applet.start!(route, code)
        state

      "uninstall " <> route ->
        route = String.trim(route)
        Logger.notice("Applet client #{client.port} uninstall #{route}")
        :ok = Store.delete(route)
        :ok = Applet.stop!(route)
        state

      "reboot\n" ->
        Logger.notice("Applet client #{client.port} reboot")
        :ok = Applet.reboot!()
        state

      "restart\n" ->
        Logger.notice("Applet client #{client.port} restart")
        :ok = Applet.restart!()
        state

      "cleanup\n" ->
        Logger.notice("Applet client #{client.port} cleanup")
        :ok = Applet.reset!()
        state

      "list stored\n" ->
        fun = fn n -> :ok = Tcp.write(client, ">#{n}\n") end
        Store.keys() |> Enum.each(fun)
        state

      "list started\n" ->
        fun = fn {_, n} -> :ok = Tcp.write(client, ">#{n}\n") end
        Multiple.lookup(:applet) |> Enum.each(fun)
        state

      "ansicolor " <> ansicolor ->
        ansicolor = String.trim(ansicolor)
        Logger.notice("Applet client #{client.port} ansicolor #{ansicolor}")
        ansicolor = String.to_existing_atom(ansicolor)
        Map.put(state, :ansicolor, ansicolor)

      "localtime " <> localtime ->
        localtime = String.trim(localtime)
        Logger.notice("Applet client #{client.port} localtime #{localtime}")
        local = NaiveDateTime.from_iso8601!(localtime)
        utc = NaiveDateTime.utc_now()
        diff = NaiveDateTime.diff(local, utc)
        Map.put(state, :localdiff, diff)

      "run trace " <> route ->
        run_loop("trace", client, state, route, cmd)

      "run debug " <> route ->
        run_loop("debug", client, state, route, cmd)

      "run info " <> route ->
        run_loop("info", client, state, route, cmd)

      "trace " <> route ->
        log_loop("trace", client, state, route, cmd)

      "debug " <> route ->
        log_loop("debug", client, state, route, cmd)

      "info " <> route ->
        log_loop("info", client, state, route, cmd)

      _ ->
        {:error, cmd}
    end
  end

  defp run_loop(level, client, state, route, cmd) do
    route = String.trim(route)
    defer(fn -> Applet.stop!(route) end)
    Logger.notice("Applet client #{client.port} run #{level} #{route}")
    Applet.stop!(route)
    code = Applet.load!(route)
    log_loop(level, client, state, route, cmd, code)
  end

  defp log_loop(level, client, state, route, cmd, code \\ nil) do
    async_read(client)
    route = String.trim(route)
    Logger.notice("Applet client #{client.port} #{level} #{route}")
    level = String.to_existing_atom(level)
    Applet.subscribe!(level, route, client)
    if code, do: {:ok, _pid} = Applet.start!(route, code)
    :ok = Tcp.write(client, ["ok ", cmd])
    log_loop(client, route, state)
  end

  defp log_loop(client, route, state = %{colors: colors}) do
    receive do
      {{:logger, ^route, type}, ^client, msg} ->
        ansicolor = Map.get(state, :ansicolor, false)
        color = if ansicolor, do: colors[type]
        localdiff = Map.get(state, :localdiff, 0)
        utc = NaiveDateTime.utc_now()
        now = NaiveDateTime.add(utc, localdiff, :second)
        log = Utils.fmt(color, now, type, msg)
        :ok = Tcp.write(client, log)
        log_loop(client, route, state)

      unexpected ->
        unexpected
    end
  end

  defp async_read(client) do
    pid = self()
    Tasks.async(fn -> send(pid, Tcp.read(client)) end)
  end

  defp defer(fun) do
    pid = self()

    Tasks.async(fn ->
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, ^pid, _} -> :ok
      end

      Utils.run_safe(fun)
    end)
  end
end
