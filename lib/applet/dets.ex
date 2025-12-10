defmodule Applet.Dets do
  require Logger
  @table_opts [type: :set, ram_file: true]

  def open(table), do: :dets.open_file(table, @table_opts)
  def lookup(table, key), do: exec(table, fn -> :dets.lookup(table, key) end)
  def delete(table, key), do: exec(table, fn -> :dets.delete(table, key) end, true)
  def upsert(table, key, data), do: exec(table, fn -> :dets.insert(table, {key, data}) end, true)
  def delete_all(table), do: exec(table, fn -> :dets.delete_all_objects(table) end, true)

  def keys(table) do
    exec(table, fn -> :dets.foldl(fn {n, _}, acc -> [n | acc] end, [], table) end)
  end

  def list(table) do
    capture = fn x -> {:continue, x} end
    exec(table, fn -> :dets.traverse(table, capture) end)
  end

  def exec(table, callback, sync \\ false) do
    response = callback.()
    if sync, do: :ok = :dets.sync(table)
    response
  end

  defmacro __using__(_) do
    quote do
      alias Applet.Shared
      alias Applet.Dets
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
        config = Application.get_env(:applet, __MODULE__)
        table = config[:table]
        table = Path.expand(table)
        module = String.trim_leading("#{__MODULE__}", "Elixir.Applet.")
        Shared.put("applets:dets:#{module}", table)
        Logger.notice("Applet dets module #{module} table #{table}")
        table = to_charlist(table)
        {:ok, table} = Dets.open(table)
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
  end
end
