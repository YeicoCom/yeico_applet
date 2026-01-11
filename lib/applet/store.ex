defmodule Applet.Store do
  alias Applet.Shared
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :args, name: __MODULE__)
  end

  def list(), do: GenServer.call(__MODULE__, :list)
  def keys(), do: GenServer.call(__MODULE__, :keys)
  def clear(), do: GenServer.call(__MODULE__, :clear)
  def get(key), do: GenServer.call(__MODULE__, {:get, key})
  def delete(key), do: GenServer.call(__MODULE__, {:delete, key})
  def put(key, data), do: GenServer.call(__MODULE__, {:put, key, data})

  def init(:args) do
    path = path()
    path |> File.mkdir_p!()
    Shared.put("applets:store", path)
    Logger.notice("Applet store #{path}")
    CubDB.start_link(path)
  end

  def path() do
    Application.get_env(:applet, :store)
  end

  def handle_call(:list, _from, table) do
    {:reply, list(table), table}
  end

  def handle_call(:keys, _from, table) do
    {:reply, keys(table), table}
  end

  def handle_call(:clear, _from, table) do
    {:reply, CubDB.clear(table), table}
  end

  def handle_call({:put, key, data}, _from, table) do
    {:reply, CubDB.put(table, key, data), table}
  end

  def handle_call({:delete, key}, _from, table) do
    {:reply, CubDB.delete(table, key), table}
  end

  def handle_call({:get, key}, _from, table) do
    {:reply, CubDB.get(table, key), table}
  end

  defp keys(table) do
    list(table) |> Enum.map(fn {k, _} -> k end)
  end

  defp list(table) do
    CubDB.select(table) |> Enum.to_list()
  end
end
