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
    run = fn -> serve(client, %{}) end
    clean = fn -> :ok = Tcp.close(client) end
    %Task{} = Tasks.async(run, clean)
    accept(server)
  end

  defp serve(client, state) do
    state =
      case Tcp.read(client) do
        {:ok, "save " <> path} ->
          path = String.trim(path)
          Logger.notice("Applet client #{client.port} save #{path}")
          {name, data} = Applet.load!(path)
          :ok = Store.upsert(name, data)
          state

        {:ok, "delete " <> name} ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} delete #{name}")
          :ok = Store.delete(name)
          state

        {:ok, "start " <> name} ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} start #{name}")
          [{^name, data}] = Store.lookup(name)
          {:ok, _pid} = Applet.start!(name, data)
          state

        {:ok, "stop " <> name} ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} stop #{name}")
          :ok = Applet.stop!(name)
          state

        {:ok, "list saved\n"} ->
          fun = fn n -> :ok = Tcp.write(client, ">#{n}\n") end
          Store.keys() |> Enum.each(fun)
          state

        {:ok, "list started\n"} ->
          fun = fn {_, n} -> :ok = Tcp.write(client, ">#{n}\n") end
          Multiple.lookup(:applet) |> Enum.each(fun)
          state

        {:ok, "localtime " <> localtime} ->
          localtime = String.trim(localtime)
          Logger.notice("Applet client #{client.port} localtime #{localtime}")
          local = NaiveDateTime.from_iso8601!(localtime)
          utc = NaiveDateTime.utc_now()
          diff = NaiveDateTime.diff(utc, local)
          state = state |> Map.put(:localtime, localtime)
          state |> Map.put(:diffsec, diff)

        {:ok, "trace " <> name} ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} trace #{name}")
          Api.Bus.subscribe!({:logger, name, :trace}, client)
          Api.Bus.subscribe!({:logger, name, :debug}, client)
          Api.Bus.subscribe!({:logger, name, :info}, client)
          Api.Bus.subscribe!({:logger, name, :warn}, client)
          Api.Bus.subscribe!({:logger, name, :error}, client)
          log_loop(client, name, state)
          state

        {:ok, "debug " <> name} ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} debug #{name}")
          Api.Bus.subscribe!({:logger, name, :debug}, client)
          Api.Bus.subscribe!({:logger, name, :info}, client)
          Api.Bus.subscribe!({:logger, name, :warn}, client)
          Api.Bus.subscribe!({:logger, name, :error}, client)
          log_loop(client, name, state)
          state

        {:ok, "info " <> name} ->
          name = String.trim(name)
          Logger.notice("Applet client #{client.port} info #{name}")
          Api.Bus.subscribe!({:logger, name, :info}, client)
          Api.Bus.subscribe!({:logger, name, :warn}, client)
          Api.Bus.subscribe!({:logger, name, :error}, client)
          log_loop(client, name, state)
          state
      end

    :ok = Tcp.write(client, "ok\n")
    serve(client, state)
  end

  defp log_loop(client, name, state) do
    receive do
      {{:logger, ^name, type}, ^client, msg} ->
        type = type |> Atom.to_string() |> String.upcase()
        # America/Mexico_City
        diffsec = Map.get(state, :diffsec, 0)
        utc = NaiveDateTime.utc_now()
        now = NaiveDateTime.shift(utc, second: diffsec)
        :ok = Tcp.write(client, log_io(now, name, type, msg))
    end

    log_loop(client, name, state)
  end

  defp log_io(now, _name, type, msg) when is_binary(msg) do
    [
      NaiveDateTime.to_iso8601(now),
      " ",
      type,
      " ",
      msg,
      "\n"
    ]
  end
end
