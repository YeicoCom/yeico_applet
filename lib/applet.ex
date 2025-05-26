defmodule Applet do
  use Applet.Alias

  def save!(name, code) do
    :ok = Store.upsert(name, code)
  end

  def delete!(name) do
    :ok = Store.delete(name)
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

  def stop!(name) do
    :ok = Utils.kill_unique({:applet, name})
    :ok = Utils.kill_multiple({:applet, name})
  end

  def list() do
    Multiple.lookup(:applet)
  end
end
