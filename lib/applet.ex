defmodule Applet do
  use Applet.Alias
  alias Applet.Api.Bus

  @delay 1
  @times 4_000

  def started?() do
    Shared.get("applets:started", false)
  end

  def start() do
    File.mkdir_p!(path())
    Shared.put("applets:path", path())
    Shared.put("applets:started", true)
  end

  def path() do
    config = Application.get_env(:applet, __MODULE__)
    path = config[:path] |> Path.expand()
    Shared.get("applets:path", path)
  end

  # for scripts and subscripts
  # tryout.exs
  # tryout/tryout.exs
  def load!(route) do
    File.read!(Path.join(path(), route))
  end

  def await(poll \\ 100) do
    Stream.interval(poll)
    |> Stream.take_while(fn _ -> not started?() end)
    |> Stream.take(-1)
    |> Enum.to_list()
    |> is_list()
  end

  def store!(route) do
    # no sense to individualize applet path
    # since there is a single statics folder
    # nil content to read code on load
    :ok = Store.upsert(route, nil)
  end

  def delete!(route) do
    :ok = Store.delete(route)
  end

  # functions only to avoid poluting module space
  # spawn_link only to ensure proper cleanup
  # do not change the pwd or any other environment
  def start!(route, opts \\ []) do
    code = Keyword.get(opts, :code)
    code = code || load!(route)
    argv = Keyword.get(opts, :argv, [])
    start = {Runner, :start_link, [route, code, argv]}
    # temporary never restarted
    # dynamic supervisor requires but ignores id
    spec = %{id: route, start: start, restart: :temporary}
    {:ok, pid} = Dynamic.start_child(spec)
    fun = fn -> [{^pid, _}] = Unique.lookup({:applet, route}) end
    :ok = Utils.wait_success(@delay, @times, fun)
    {:ok, pid}
  end

  def stop!(route) do
    :ok = Utils.kill_unique({:applet, route})
    :ok = Utils.kill_multiple({:applet, route})
    await!(route)
  end

  def await!(route) do
    fun = fn -> [] = Unique.lookup({:applet, route}) end
    :ok = Utils.wait_success(@delay, @times, fun)
    fun = fn -> [] = Multiple.lookup({:applet, route}) end
    :ok = Utils.wait_success(@delay, @times, fun)
  end

  def reboot!() do
    list = started()
    list |> Enum.each(fn {_, route} -> stop!(route) end)
    list = stored()
    list |> Enum.each(fn route -> start!(route) end)
  end

  def restart!() do
    list = started()
    list |> Enum.each(fn {_, route} -> stop!(route) end)
    list |> Enum.each(fn {_, route} -> start!(route) end)
  end

  def reset!() do
    list = stored()
    list |> Enum.each(fn route -> :ok = Store.delete(route) end)
    list = started()
    list |> Enum.each(fn {_, route} -> stop!(route) end)
  end

  def started() do
    Multiple.lookup(:applet)
  end

  def stored() do
    Store.keys()
  end

  def subscribe!(level, route, sargs \\ nil)

  def subscribe!(:trace, route, sargs) do
    Bus.subscribe!({:logger, route, :trace}, sargs)
    subscribe!(:debug, route, sargs)
  end

  def subscribe!(:debug, route, sargs) do
    Bus.subscribe!({:logger, route, :debug}, sargs)
    subscribe!(:info, route, sargs)
  end

  def subscribe!(:info, route, sargs) do
    Bus.subscribe!({:logger, route, :info}, sargs)
    Bus.subscribe!({:logger, route, :warn}, sargs)
    Bus.subscribe!({:logger, route, :error}, sargs)
  end

  # for iex
  #
  # Applet.run!("tryout.exs")
  # runs ${PWD}/applets/tryout.exs
  #
  # Applet.run!("tryout.exs", code: "")
  # runs passed code ""
  #
  # type INTRO to stop logging
  def run!(route, opts \\ []) do
    code = Keyword.get(opts, :code)
    code = code || load!(route)
    argv = Keyword.get(opts, :argv, [])
    run = fn -> start!(route, code: code, argv: argv) end
    opts = Keyword.drop(opts, [:code, :argv])
    opts = Keyword.merge(opts, stop: true, run: run)
    log(route, opts)
  end

  # for iex
  #
  # type INTRO to stop logging
  def log(route, opts \\ []) do
    run = Keyword.get(opts, :run)
    await = Keyword.get(opts, :await, fn task -> Task.await(task, :infinity) end)
    read = Keyword.get(opts, :read, fn -> IO.read(:line) end)
    write = Keyword.get(opts, :write, &IO.write/1)
    level = Keyword.get(opts, :level, :trace)
    colored = Keyword.get(opts, :colored, true)
    stop = Keyword.get(opts, :stop, false)
    local = NaiveDateTime.local_now() |> NaiveDateTime.to_iso8601
    local = Keyword.get(opts, :local, local)
    local = NaiveDateTime.from_iso8601!(local)
    utc = NaiveDateTime.utc_now()
    diff = NaiveDateTime.diff(local, utc)
    # Use Task because Tasks points to a different stdin
    # handle async to avoid tainting the iex process
    Task.async(fn ->
      pid = self()

      Task.async(fn ->
        line = read.()
        send(pid, {:stdin, :line, line})
      end)

      subscribe!(level, route, nil)
      if run, do: run.()

      colors =
        Application.get_env(:applet, Applet.Server)[:colors] ||
          [
            trace: IO.ANSI.light_black(),
            debug: IO.ANSI.light_cyan(),
            info: IO.ANSI.blue(),
            warn: IO.ANSI.yellow(),
            error: IO.ANSI.light_red()
          ]

      colors = Enum.into(colors, %{})

      loop = fn loop ->
        receive do
          {:stdin, :line, _line} ->
            if stop, do: stop!(route)

          {{:logger, ^route, type}, nil, msg} ->
            utc = NaiveDateTime.utc_now()
            now = NaiveDateTime.add(utc, diff, :second)
            color = if colored, do: colors[type]
            log = Utils.fmt_log(color, now, type, msg)
            write.(log)
            loop.(loop)
        end
      end

      loop.(loop)
    end)
    |> await.()
  end
end
