defmodule Applet do
  use Applet.Alias

  def path() do
    Shared.get("applets:path", "#{File.cwd!()}/applets")
  end

  def path(value) do
    Shared.put("applets:path", value)
  end

  def await(poll \\ 100) do
    Stream.interval(poll)
    |> Stream.take_while(fn _ -> not Shared.get("applets:started", false) end)
    |> Stream.take(-1)
    |> Enum.to_list()
    |> is_list()
  end

  def save!(name, code) do
    :ok = Store.upsert(name, code)
  end

  def delete!(name) do
    :ok = Store.delete(name)
  end

  def load!(path) do
    name = Path.basename(path, ".exs")
    data = File.read!(path)
    {name, data}
  end

  # functions only to avoid poluting module space
  # spawn_link only to ensure proper cleanup
  # do not change the pwd or any other environment
  def start!(name, code) do
    start = {Runner, :start_link, [name, code]}
    # temporary never restarted
    # dynamic supervisor requires but ignores id
    spec = %{id: name, start: start, restart: :temporary}
    {:ok, _pid} = Dynamic.start_child(spec)
  end

  def stop!(name, to \\ 5_000) when to > 0 do
    :ok = Utils.kill_unique({:applet, name})
    :ok = Utils.kill_multiple({:applet, name})
    Utils.wait_success(1, to, fn -> [] = Unique.lookup({:applet, name}) end)
    Utils.wait_success(1, to, fn -> [] = Multiple.lookup({:applet, name}) end)
  end

  def list() do
    Multiple.lookup(:applet)
  end
end
