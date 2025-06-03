defmodule Applet do
  use Applet.Alias
  alias Applet.Api.Bus

  def start() do
    Shared.put("applets:path", path())
    Shared.put("applets:started", true)
  end

  def path() do
    # HOME works for production
    # File.cwd! works for both
    default = "#{File.cwd!()}/applets"
    Shared.get("applets:path", default)
  end

  def path(value) do
    Shared.put("applets:path", value)
  end

  # for scripts and subscripts
  # tryout.exs
  # tryout/tryout.exs
  def load!(route) do
    path = Path.join(Applet.path(), route)
    File.read!(path)
  end

  def started?() do
    Shared.get("applets:started", false)
  end

  def await(poll \\ 100) do
    Stream.interval(poll)
    |> Stream.take_while(fn _ -> not started?() end)
    |> Stream.take(-1)
    |> Enum.to_list()
    |> is_list()
  end

  def save!(route, code) do
    :ok = Store.upsert(route, code)
  end

  def delete!(route) do
    :ok = Store.delete(route)
  end

  # functions only to avoid poluting module space
  # spawn_link only to ensure proper cleanup
  # do not change the pwd or any other environment
  def start!(route, code) do
    start = {Runner, :start_link, [route, code]}
    # temporary never restarted
    # dynamic supervisor requires but ignores id
    spec = %{id: route, start: start, restart: :temporary}
    {:ok, _pid} = Dynamic.start_child(spec)
  end

  def stop!(route, to \\ 5_000) when to > 0 do
    :ok = Utils.kill_unique({:applet, route})
    :ok = Utils.kill_multiple({:applet, route})
    :ok = Utils.wait_success(1, to, fn -> [] = Unique.lookup({:applet, route}) end)
    :ok = Utils.wait_success(1, to, fn -> [] = Multiple.lookup({:applet, route}) end)
  end

  def running() do
    Multiple.lookup(:applet)
  end

  def saved() do
    Store.keys()
  end

  def log(color, dt, type, msg) when is_binary(msg) do
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

  # for iex
  # Applet.run!("tryout.exs")
  # runs ${PWD}/applets/tryout.exs
  # Applet.run!("tryout/tryout.exs")
  # runs ${PWD}/applets/tryout/tryout.exs
  # type INTRO to stop logging
  def run!(route) do
    Applet.start()
    code = Applet.load!(route)

    # Use Task because Tasks points to a different stdin
    Task.async(fn ->
      Bus.subscribe!({:logger, route, :trace}, nil)
      Bus.subscribe!({:logger, route, :debug}, nil)
      Bus.subscribe!({:logger, route, :info}, nil)
      Bus.subscribe!({:logger, route, :warn}, nil)
      Bus.subscribe!({:logger, route, :error}, nil)

      pid = self()

      Task.async(fn ->
        line = IO.read(:line)
        send(pid, {:stdin, :line, line})
      end)

      Task.async(fn -> start!(route, code) end)
      config = Server.config()
      colors = config[:colors]

      loop = fn loop ->
        receive do
          {:stdin, :line, _line} ->
            :ok

          {{:logger, ^route, type}, nil, msg} ->
            now = NaiveDateTime.local_now()
            IO.write(log(colors[type], now, type, msg))
            loop.(loop)
        end
      end

      loop.(loop)
    end)
    |> Task.await(:infinity)

    stop!(route)
  end
end
