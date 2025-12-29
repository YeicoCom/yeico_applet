defmodule Applet.StoreTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "crud" do
    assert :ok == Store.delete_all()

    test_empty = fn ->
      assert [] == Store.keys()
      assert [] == Store.list()
      assert [] == Store.lookup(:key)
      assert :ok == Store.delete(:key)
      assert :ok == Store.delete_all()
    end

    # empty
    test_empty.()

    # upsert delete
    assert :ok = Store.upsert(:key, "value")
    assert [:key] == Store.keys()
    assert [key: "value"] == Store.list()
    assert [key: "value"] == Store.lookup(:key)
    assert :ok == Store.delete(:key)
    test_empty.()

    # upsert delete_all
    assert :ok = Store.upsert(:key, "value")
    assert [:key] == Store.keys()
    assert [key: "value"] == Store.list()
    assert [key: "value"] == Store.lookup(:key)
    assert :ok == Store.delete_all()
    test_empty.()

    # upsert upsert
    assert :ok = Store.upsert(:key, "insert")
    assert [:key] == Store.keys()
    assert [key: "insert"] == Store.list()
    assert [key: "insert"] == Store.lookup(:key)
    assert :ok = Store.upsert(:key, "update")
    assert [:key] == Store.keys()
    assert [key: "update"] == Store.list()
    assert [key: "update"] == Store.lookup(:key)
  end
end
