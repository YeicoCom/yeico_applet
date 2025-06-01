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
    colors = config[:colors] |> Enum.into(%{})
    task = Tasks.async(fn -> init(port, colors) end)
    {:ok, Api.pid(task)}
  end

  defp init(port, colors) do
    true = Process.register(self(), __MODULE__)

    Store.list()
    |> Enum.each(fn {n, d} ->
      Logger.notice("Applet auto start #{n}")
      Applet.start!(n, d)
    end)

    {:ok, server} = Tcp.listen("127.0.0.1", port, line: true)
    Logger.notice("Applet Server port #{server.port}")
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
        "save " <> path ->
          path = String.trim(path)
          Logger.notice("Applet client #{client.port} save #{path}")
          {name, data} = Applet.load!(path)
          :ok = Store.upsert(name, data)
          state

        "delete " <> name ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} delete #{name}")
          :ok = Store.delete(name)
          state

        "start " <> name ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} start #{name}")
          [{^name, data}] = Store.lookup(name)
          {:ok, _pid} = Applet.start!(name, data)
          state

        "stop " <> name ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} stop #{name}")
          :ok = Applet.stop!(name)
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

        "trace " <> name ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} trace #{name}")
          Api.Bus.subscribe!({:logger, name, :trace}, client)
          Api.Bus.subscribe!({:logger, name, :debug}, client)
          Api.Bus.subscribe!({:logger, name, :info}, client)
          Api.Bus.subscribe!({:logger, name, :warn}, client)
          Api.Bus.subscribe!({:logger, name, :error}, client)
          :ok = Tcp.write(client, ["ok ", cmd])
          log_loop(client, name, state)
          state

        "debug " <> name ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} debug #{name}")
          Api.Bus.subscribe!({:logger, name, :debug}, client)
          Api.Bus.subscribe!({:logger, name, :info}, client)
          Api.Bus.subscribe!({:logger, name, :warn}, client)
          Api.Bus.subscribe!({:logger, name, :error}, client)
          :ok = Tcp.write(client, ["ok ", cmd])
          log_loop(client, name, state)
          state

        "info " <> name ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} info #{name}")
          Api.Bus.subscribe!({:logger, name, :info}, client)
          Api.Bus.subscribe!({:logger, name, :warn}, client)
          Api.Bus.subscribe!({:logger, name, :error}, client)
          :ok = Tcp.write(client, ["ok ", cmd])
          log_loop(client, name, state)
          state
      end

    :ok = Tcp.write(client, ["ok ", cmd])
    serve(client, state)
  end

  defp log_loop(client, name, state = %{colors: colors}) do
    receive do
      {{:logger, ^name, type}, ^client, msg} ->
        ansicolor = Map.get(state, :ansicolor, false)
        color = if ansicolor, do: colors[type]
        type = type |> Atom.to_string() |> String.upcase()
        localdiff = Map.get(state, :localdiff, 0)
        utc = NaiveDateTime.utc_now()
        now = NaiveDateTime.add(utc, localdiff, :second)
        :ok = Tcp.write(client, log_io(color, now, type, msg))
    end

    log_loop(client, name, state)
  end

  defp log_io(color, now, type, msg) when is_binary(msg) do
    [
      if(color, do: color, else: ""),
      NaiveDateTime.to_iso8601(now),
      " ",
      type,
      " ",
      msg,
      if(color, do: IO.ANSI.reset(), else: ""),
      "\n"
    ]
  end
end
