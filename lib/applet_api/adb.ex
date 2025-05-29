defmodule Applet.Api.Adb do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def keys() do
    Agent.get(__MODULE__, &Map.keys(&1))
  end

  def list() do
    Agent.get(__MODULE__, &Map.to_list(&1))
  end

  def has_key?(key) do
    Agent.get(__MODULE__, &Map.has_key?(&1, key))
  end

  def get(key, def \\ nil) do
    Agent.get(__MODULE__, &Map.get(&1, key, def))
  end

  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  def delete(key) do
    Agent.get_and_update(__MODULE__, &{Map.get(&1, key), Map.delete(&1, key)})
  end
end
