defmodule Applet.Dets do
  @table_opts [type: :set, ram_file: true]

  def open(table), do: :dets.open_file(table, @table_opts)
  def lookup(table, key), do: exec(table, fn -> :dets.lookup(table, key) end)
  def delete(table, key), do: exec(table, fn -> :dets.delete(table, key) end, true)
  def upsert(table, key, data), do: exec(table, fn -> :dets.insert(table, {key, data}) end, true)

  def list(table) do
    capture = fn x -> {:continue, x} end
    exec(table, fn -> :dets.traverse(table, capture) end)
  end

  def exec(table, callback, sync \\ false) do
    response = callback.()
    if sync, do: :ok = :dets.sync(table)
    response
  end

  defmacro __using__(table: table) do
    table = to_charlist(table)

    quote do
      alias Applet.Dets
      @table_name unquote(table)
      defp db_open(), do: Dets.open(@table_name)
      defp db_lookup(key), do: Dets.lookup(@table_name, key)
      defp db_delete(key), do: Dets.delete(@table_name, key)
      defp db_upsert(key, data), do: Dets.upsert(@table_name, key, data)
      defp db_list(), do: Dets.list(@table_name)
    end
  end
end
