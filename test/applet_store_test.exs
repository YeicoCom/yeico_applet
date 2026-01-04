defmodule Applet.StoreTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "crud" do
    assert :ok == Store.clear()

    test_empty = fn ->
      assert [] == Store.keys()
      assert [] == Store.list()
      assert nil == Store.get(:key)
      assert :ok == Store.delete(:key)
      assert :ok == Store.clear()
    end

    # empty
    test_empty.()

    # upsert delete
    assert :ok = Store.put(:key, "value")
    assert [:key] == Store.keys()
    assert [key: "value"] == Store.list()
    assert "value" == Store.get(:key)
    assert :ok == Store.delete(:key)
    test_empty.()

    # upsert delete_all
    assert :ok = Store.put(:key, "value")
    assert [:key] == Store.keys()
    assert [key: "value"] == Store.list()
    assert "value" == Store.get(:key)
    assert :ok == Store.clear()
    test_empty.()

    # upsert upsert
    assert :ok = Store.put(:key, "insert")
    assert [:key] == Store.keys()
    assert [key: "insert"] == Store.list()
    assert "insert" == Store.get(:key)
    assert :ok = Store.put(:key, "update")
    assert [:key] == Store.keys()
    assert [key: "update"] == Store.list()
    assert "update" == Store.get(:key)
  end
end
