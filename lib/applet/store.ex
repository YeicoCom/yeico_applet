defmodule Applet.Store do
  use Applet.Dets, table: "db_applet_store.dets"
  use GenServer

  def start_link(opts),
    do: GenServer.start_link(__MODULE__, :args, Keyword.merge(opts, name: __MODULE__))

  def list(), do: GenServer.call(__MODULE__, :list)
  def upsert(key, data), do: GenServer.call(__MODULE__, {:upsert, key, data})
  def delete(key), do: GenServer.call(__MODULE__, {:delete, key})
  def lookup(key), do: GenServer.call(__MODULE__, {:lookup, key})

  def init(:args) do
    {:ok, db_open()}
  end

  def handle_call(:list, _from, state) do
    {:reply, db_list(), state}
  end

  def handle_call({:upsert, key, data}, _from, state) do
    {:reply, db_upsert(key, data), state}
  end

  def handle_call({:delete, key}, _from, state) do
    {:reply, db_delete(key), state}
  end

  def handle_call({:lookup, key}, _from, state) do
    {:reply, db_lookup(key), state}
  end
end
