defmodule Applet.SharedTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "crud" do
    test_empty = fn ->
      # no reset here
      assert %{} == Shared.get()
      assert [] == Shared.keys()
      assert [] == Shared.list()
      assert nil == Shared.get(:key)
      assert :def == Shared.get(:key, :def)
      refute Shared.has_key?(:key)
      assert nil == Shared.delete(:key)
    end

    test_put_one = fn ->
      assert :ok == Shared.reset()
      assert %{} == Shared.get()
      assert :ok == Shared.put(:key, "value")
      assert [:key] == Shared.keys()
      assert [key: "value"] == Shared.list()
      assert %{key: "value"} == Shared.get()
      assert "value" == Shared.get(:key)
      assert "value" == Shared.get(:key, :def)
      assert Shared.has_key?(:key)
    end

    test_put_all = fn ->
      assert :ok == Shared.reset()
      assert %{} == Shared.get()
      assert :ok == Shared.put(%{key: "value"})
      assert [:key] == Shared.keys()
      assert [key: "value"] == Shared.list()
      assert %{key: "value"} == Shared.get()
      assert "value" == Shared.get(:key)
      assert "value" == Shared.get(:key, :def)
      assert Shared.has_key?(:key)
    end

    test_key_updater = fn ->
      assert :ok == Shared.reset()
      assert %{} == Shared.get()
      assert :ok == Shared.update(:key, "value0", fn _ -> "value1" end)
      assert %{key: "value0"} == Shared.get()
      assert :ok == Shared.update(:key, "value0", fn _ -> "value2" end)
      assert %{key: "value2"} == Shared.get()
      assert :ok == Shared.update(:key, "value0", fn _ -> "value3" end)
      assert %{key: "value3"} == Shared.get()
    end

    test_map_updater = fn ->
      assert :ok == Shared.reset()
      assert %{} == Shared.get()
      assert :ok == Shared.update(fn map -> Map.put(map, :key, "value1") end)
      assert %{key: "value1"} == Shared.get()
      assert :ok == Shared.update(fn map -> Map.put(map, :key, "value2") end)
      assert %{key: "value2"} == Shared.get()
    end

    assert :ok == Shared.reset()

    # empty
    test_empty.()

    # put one and reset
    test_put_one.()
    assert :ok == Shared.reset()
    test_empty.()

    # put one and put empty
    test_put_one.()
    assert :ok == Shared.put(%{})
    test_empty.()

    # put one and delete
    test_put_one.()
    assert "value" == Shared.delete(:key)
    test_empty.()

    # put all and reset
    test_put_all.()
    assert :ok == Shared.reset()
    test_empty.()

    test_map_updater.()
    test_key_updater.()
  end
end
