defmodule Applet do
  use Applet.Alias

  def save!(name, code) do
    :ok = Store.upsert(name, code)
  end

  def delete!(name) do
    :ok = Store.delete(name)
  end

  def start!(name, code) do
    start = {Runner, :start_link, [name, code]}
    # temporary never restarted
    # dynamic supervisor require but ignore id
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
