defmodule Applet.AdbTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "crud" do
    test_empty = fn ->
      # no reset here
      assert %{} == Adb.get()
      assert [] == Adb.keys()
      assert [] == Adb.list()
      assert nil == Adb.get(:key)
      assert :def == Adb.get(:key, :def)
      refute Adb.has_key?(:key)
      assert nil == Adb.delete(:key)
    end

    test_put_one = fn ->
      assert :ok == Adb.reset()
      assert %{} == Adb.get()
      assert :ok == Adb.put(:key, "value")
      assert [:key] == Adb.keys()
      assert [key: "value"] == Adb.list()
      assert %{key: "value"} == Adb.get()
      assert "value" == Adb.get(:key)
      assert "value" == Adb.get(:key, :def)
      assert Adb.has_key?(:key)
    end

    test_put_all = fn ->
      assert :ok == Adb.reset()
      assert %{} == Adb.get()
      assert :ok == Adb.put(%{key: "value"})
      assert [:key] == Adb.keys()
      assert [key: "value"] == Adb.list()
      assert %{key: "value"} == Adb.get()
      assert "value" == Adb.get(:key)
      assert "value" == Adb.get(:key, :def)
      assert Adb.has_key?(:key)
    end

    test_key_updater = fn ->
      assert :ok == Adb.reset()
      assert %{} == Adb.get()
      assert :ok == Adb.update(:key, "value0", fn _ -> "value1" end)
      assert %{key: "value0"} == Adb.get()
      assert :ok == Adb.update(:key, "value0", fn _ -> "value2" end)
      assert %{key: "value2"} == Adb.get()
      assert :ok == Adb.update(:key, "value0", fn _ -> "value3" end)
      assert %{key: "value3"} == Adb.get()
    end

    test_map_updater = fn ->
      assert :ok == Adb.reset()
      assert %{} == Adb.get()
      assert :ok == Adb.update(fn map -> Map.put(map, :key, "value1") end)
      assert %{key: "value1"} == Adb.get()
      assert :ok == Adb.update(fn map -> Map.put(map, :key, "value2") end)
      assert %{key: "value2"} == Adb.get()
    end

    assert :ok == Adb.reset()

    # empty
    test_empty.()

    # put one and reset
    test_put_one.()
    assert :ok == Adb.reset()
    test_empty.()

    # put one and put empty
    test_put_one.()
    assert :ok == Adb.put(%{})
    test_empty.()

    # put one and delete
    test_put_one.()
    assert "value" == Adb.delete(:key)
    test_empty.()

    # put all and reset
    test_put_all.()
    assert :ok == Adb.reset()
    test_empty.()

    test_map_updater.()
    test_key_updater.()
  end

  test "replace for putcast!" do
    assert :ok == Adb.reset()
    assert :ok == Adb.put(:key, 1)
    assert 1 == Adb.replace(:key, 2)
    assert 2 == Adb.replace(:key, 3)
  end
end
