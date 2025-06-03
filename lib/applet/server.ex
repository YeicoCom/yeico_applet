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
    run = fn -> serve(client, %{colors: colors}) end
    clean = fn -> :ok = Tcp.close(client) end
    %Task{} = Tasks.async(run, clean)
    accept(server, colors)
  end

  defp serve(client, state) do
    {:ok, cmd} = Tcp.read(client)

    state =
      case cmd do
        "save " <> route ->
          route = String.trim(route)
          Logger.notice("Applet client #{client.port} save #{route}")
          code = Applet.load!(route)
          :ok = Store.upsert(route, code)
          state

        "delete " <> route ->
          route = String.trim(route)
          Logger.notice("Applet client #{client.port} delete #{route}")
          :ok = Store.delete(route)
          state

        "start " <> route ->
          route = String.trim(route)
          Logger.notice("Applet client #{client.port} start #{route}")
          [{^route, data}] = Store.lookup(route)
          {:ok, _pid} = Applet.start!(route, data)
          state

        "stop " <> route ->
          route = String.trim(route)
          Logger.notice("Applet client #{client.port} stop #{route}")
          :ok = Applet.stop!(route)
          state

        "list saved\n" ->
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

        "trace " <> route ->
          route = String.trim(route)
          Logger.notice("Applet client #{client.port} trace #{route}")
          Api.Bus.subscribe!({:logger, route, :trace}, client)
          Api.Bus.subscribe!({:logger, route, :debug}, client)
          Api.Bus.subscribe!({:logger, route, :info}, client)
          Api.Bus.subscribe!({:logger, route, :warn}, client)
          Api.Bus.subscribe!({:logger, route, :error}, client)
          :ok = Tcp.write(client, ["ok ", cmd])
          log_loop(client, route, state)
          state

        "debug " <> route ->
          route = String.trim(route)
          Logger.notice("Applet client #{client.port} debug #{route}")
          Api.Bus.subscribe!({:logger, route, :debug}, client)
          Api.Bus.subscribe!({:logger, route, :info}, client)
          Api.Bus.subscribe!({:logger, route, :warn}, client)
          Api.Bus.subscribe!({:logger, route, :error}, client)
          :ok = Tcp.write(client, ["ok ", cmd])
          log_loop(client, route, state)
          state

        "info " <> route ->
          route = String.trim(route)
          Logger.notice("Applet client #{client.port} info #{route}")
          Api.Bus.subscribe!({:logger, route, :info}, client)
          Api.Bus.subscribe!({:logger, route, :warn}, client)
          Api.Bus.subscribe!({:logger, route, :error}, client)
          :ok = Tcp.write(client, ["ok ", cmd])
          log_loop(client, route, state)
          state
      end

    :ok = Tcp.write(client, ["ok ", cmd])
    serve(client, state)
  end

  defp log_loop(client, route, state = %{colors: colors}) do
    receive do
      {{:logger, ^route, type}, ^client, msg} ->
        ansicolor = Map.get(state, :ansicolor, false)
        color = if ansicolor, do: colors[type]
        localdiff = Map.get(state, :localdiff, 0)
        utc = NaiveDateTime.utc_now()
        now = NaiveDateTime.add(utc, localdiff, :second)
        log = Applet.log(color, now, type, msg)
        :ok = Tcp.write(client, log)
    end

    log_loop(client, route, state)
  end
end
