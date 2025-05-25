defmodule Applet.Adb do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  # Adb.pid()
  def pid() do
    Process.whereis(__MODULE__)
  end

  # Adb.kill()
  def kill() do
    Process.whereis(__MODULE__)
    |> Process.exit(:kill)
  end

  # Adb.keys()
  def keys() do
    Agent.get(__MODULE__, &Map.keys(&1))
  end

  # Adb.list()
  def list() do
    Agent.get(__MODULE__, &Map.to_list(&1))
  end

  # Adb.has_key?(:tryout)
  def has_key?(key) do
    Agent.get(__MODULE__, &Map.has_key?(&1, key))
  end

  # Adb.get(:tryout)
  def get(key, def \\ nil) do
    Agent.get(__MODULE__, &Map.get(&1, key, def))
  end

  # Adb.put(:tryout, "tryout")
  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  # Adb.delete(:tryout)
  def delete(key) do
    Agent.get_and_update(__MODULE__, &{Map.get(&1, key), Map.delete(&1, key)})
  end
end
