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
end
