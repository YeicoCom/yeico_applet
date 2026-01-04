defmodule Applet do
  use Applet.Alias

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
    path = Application.get_env(:applet, :path)
    Shared.get("applets:path", path)
  end

  def path(route) do
    Path.join(path(), route)
  end

  # for scripts and subscripts
  # tryout.exs
  # tryout/tryout.exs
  def load!(route) do
    File.read!(path(route))
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
    :ok = Store.put(route, nil)
  end

  def delete!(route) do
    :ok = Store.delete(route)
  end

  # functions only to avoid poluting module space
  # spawn_link only to ensure proper cleanup
  # do not change the pwd or any other environment
  def start!(route, opts \\ []) do
    Logger.notice("Applet start!: #{route}")
    code = Keyword.get(opts, :code)
    code = code || load!(route)
    bindings = Keyword.get(opts, :bindings, [])
    start = {Runner, :start_link, [route, code, bindings]}
    # temporary never restarted, defaults to worker
    # dynamic supervisor requires but ignores id
    spec = %{id: route, start: start, restart: :temporary}
    {:ok, pid} = Dynamic.start_child(spec)
    fun = fn -> [{^pid, _}] = Unique.lookup({:applet_main, route}) end
    :ok = wait_success(@delay, @times, fun)
    {:ok, pid}
  end

  def stop!(route) do
    :ok = kill_unique({:applet_main, route})
    :ok = kill_multiple({:applet_task, route})
    await!(route)
  end

  def await!(route) do
    fun = fn -> [] = Unique.lookup({:applet_main, route}) end
    :ok = wait_success(@delay, @times, fun)
    fun = fn -> [] = Unique.lookup({:applet_super, route}) end
    :ok = wait_success(@delay, @times, fun)
    fun = fn -> [] = Multiple.lookup({:applet_task, route}) end
    :ok = wait_success(@delay, @times, fun)
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

  def reset!(except \\ nil) do
    list = stored()
    list |> Enum.filter(fn route -> route != except end) |> Enum.each(fn route -> :ok = Store.delete(route) end)
    list = started()
    list |> Enum.filter(fn {_, route} -> route != except end) |> Enum.each(fn {_, route} -> stop!(route) end)
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

  def broadcast!(route, type, msg) do
    Bus.broadcast!(:logger, {route, type, msg})
    Bus.broadcast!({:logger, route, type}, msg)
  end

  def colors() do
    Application.get_env(:applet, :colors) ||
      [
        trace: IO.ANSI.light_black(),
        debug: IO.ANSI.light_cyan(),
        info: IO.ANSI.blue(),
        warn: IO.ANSI.yellow(),
        error: IO.ANSI.light_red()
      ]
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
    bindings = Keyword.get(opts, :bindings, [])
    run = fn -> start!(route, code: code, bindings: bindings) end
    stop = Keyword.get(opts, :stop, true)
    opts = Keyword.drop(opts, [:code, :bindings])
    opts = Keyword.merge(opts, run: run, stop: stop)
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
    local = NaiveDateTime.local_now() |> NaiveDateTime.to_iso8601()
    local = Keyword.get(opts, :local, local)
    local = NaiveDateTime.from_iso8601!(local)
    utc = NaiveDateTime.utc_now()
    diff = NaiveDateTime.diff(local, utc)
    # Use Task because Tasks points to a different stdin
    # handle async to avoid tainting the iex process
    Task.async(fn ->
      pid = self()

      Task.async(fn ->
        resp = read.()
        send(pid, {:stop, :read, resp})
      end)

      subscribe!(level, route, nil)
      if run, do: run.()

      colors = Enum.into(colors(), %{})

      loop = fn loop ->
        receive do
          {:stop, _src, _resp} ->
            if stop, do: stop!(route)

          {{:logger, ^route, type}, nil, msg} ->
            utc = NaiveDateTime.utc_now()
            now = NaiveDateTime.add(utc, diff, :second)
            color = if colored, do: colors[type]
            log = format_log(color, now, type, msg)
            write.(log)
            loop.(loop)
        end
      end

      loop.(loop)
    end)
    |> await.()
  end

  def format_log(color, dt, type, msg) when is_binary(msg) do
    dt = NaiveDateTime.truncate(dt, :millisecond)

    [
      if(color, do: color, else: ""),
      NaiveDateTime.to_iso8601(dt),
      " ",
      type |> Atom.to_string() |> String.upcase(),
      " ",
      msg,
      if(color, do: IO.ANSI.reset(), else: ""),
      "\n"
    ]
  end

  def wait_success(period, times, fun) when period > 0 and times > 0 and is_function(fun, 0) do
    last = times - 1

    Stream.interval(period)
    |> Stream.take(times)
    |> Stream.with_index()
    |> Stream.map(fn {_, i} -> {i, Utils.safe(fun)} end)
    |> Stream.take_while(fn
      {_, {:error, _}} -> true
      {_, {:ok, _}} -> false
    end)
    |> Stream.take(-1)
    |> Enum.to_list()
    |> case do
      [{^last, {:error, %{error: error, stack: stack}}}] -> reraise(error, stack)
      _ -> :ok
    end
  end

  def kill_unique(key) do
    key
    |> Unique.lookup()
    |> Enum.each(&Utils.kill(elem(&1, 0)))
  end

  def kill_multiple(key) do
    key
    |> Multiple.lookup()
    |> Enum.each(&Utils.kill(elem(&1, 0)))
  end
end
