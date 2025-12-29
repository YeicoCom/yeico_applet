defmodule Applet.DetsTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "crud" do
    path = Path.expand("dets_test.dets")
    File.rm_rf!(path)
    {:ok, table} = Dets.open(path)

    test_empty = fn ->
      assert [] == Dets.keys(table)
      assert [] == Dets.list(table)
      assert [] == Dets.lookup(table, :key)
      assert :ok == Dets.delete(table, :key)
      assert :ok == Dets.delete_all(table)
    end

    # empty
    test_empty.()

    # upsert delete
    assert :ok = Dets.upsert(table, :key, "value")
    assert [:key] == Dets.keys(table)
    assert [key: "value"] == Dets.list(table)
    assert [key: "value"] == Dets.lookup(table, :key)
    assert :ok == Dets.delete(table, :key)
    test_empty.()

    # upsert delete_all
    assert :ok = Dets.upsert(table, :key, "value")
    assert [:key] == Dets.keys(table)
    assert [key: "value"] == Dets.list(table)
    assert [key: "value"] == Dets.lookup(table, :key)
    assert :ok == Dets.delete_all(table)
    test_empty.()

    # upsert upsert
    assert :ok = Dets.upsert(table, :key, "insert")
    assert [:key] == Dets.keys(table)
    assert [key: "insert"] == Dets.list(table)
    assert [key: "insert"] == Dets.lookup(table, :key)
    assert :ok = Dets.upsert(table, :key, "update")
    assert [:key] == Dets.keys(table)
    assert [key: "update"] == Dets.list(table)
    assert [key: "update"] == Dets.lookup(table, :key)
  end
end
