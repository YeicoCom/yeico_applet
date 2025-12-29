defmodule Applet.Store do
  alias Applet.Api.Dets
  alias Applet.Shared
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :args, name: __MODULE__)
  end

  def list(), do: GenServer.call(__MODULE__, :list)
  def keys(), do: GenServer.call(__MODULE__, :keys)
  def delete_all(), do: GenServer.call(__MODULE__, :delete_all)
  def upsert(key, data), do: GenServer.call(__MODULE__, {:upsert, key, data})
  def delete(key), do: GenServer.call(__MODULE__, {:delete, key})
  def lookup(key), do: GenServer.call(__MODULE__, {:lookup, key})

  def init(:args) do
    path = path()
    path |> Path.dirname() |> File.mkdir_p!()
    Shared.put("applets:dets:store", path)
    Logger.notice("Applet dets store #{path}")
    Dets.open(path) # {:ok, table}
  end

  def path() do
    Application.get_env(:applet, :store)
  end

  def handle_call(:list, _from, table) do
    {:reply, Dets.list(table), table}
  end

  def handle_call(:keys, _from, table) do
    {:reply, Dets.keys(table), table}
  end

  def handle_call(:delete_all, _from, table) do
    {:reply, Dets.delete_all(table), table}
  end

  def handle_call({:upsert, key, data}, _from, table) do
    {:reply, Dets.upsert(table, key, data), table}
  end

  def handle_call({:delete, key}, _from, table) do
    {:reply, Dets.delete(table, key), table}
  end

  def handle_call({:lookup, key}, _from, table) do
    {:reply, Dets.lookup(table, key), table}
  end
end
