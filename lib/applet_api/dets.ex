defmodule Applet.Api.Dets do
  @table_opts [type: :set, ram_file: true]

  def open(table), do: :dets.open_file(to_charlist(table), @table_opts)
  def lookup(table, key), do: exec(table, fn table -> :dets.lookup(table, key) end)
  def delete(table, key), do: exec(table, fn table -> :dets.delete(table, key) end, true)

  def upsert(table, key, data),
    do: exec(table, fn table -> :dets.insert(table, {key, data}) end, true)

  def delete_all(table), do: exec(table, fn table -> :dets.delete_all_objects(table) end, true)

  def keys(table) do
    exec(table, fn table -> :dets.foldl(fn {n, _}, acc -> [n | acc] end, [], table) end)
  end

  def list(table) do
    capture = fn x -> {:continue, x} end
    exec(table, fn table -> :dets.traverse(table, capture) end)
  end

  def exec(table, callback, sync \\ false) when is_function(callback, 1) do
    response = callback.(table)
    if sync, do: :ok = :dets.sync(table)
    response
  end
end
