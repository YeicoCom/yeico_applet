defmodule Applet.Shared do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(key, def \\ nil) do
    Agent.get(__MODULE__, &Map.get(&1, key, def))
  end

  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  def update(updater) when is_function(updater, 1) do
    Agent.update(__MODULE__, updater)
  end

  def update(key, default, updater) when is_function(updater, 1) do
    Agent.update(__MODULE__, &Map.update(&1, key, default, updater))
  end

  def delete(key) do
    Agent.get_and_update(__MODULE__, &{Map.get(&1, key), Map.delete(&1, key)})
  end
end
