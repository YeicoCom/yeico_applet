defmodule AppletEmptyTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  setup do
    Utils.wait_success(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "empty applet" do
    name = "empty"
    code = ""

    {:ok, pid} = Applet.start!(name, code)

    Utils.wait_success(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    Utils.wait_success(20, 20, fn ->
      assert [{^pid, {:ok, {nil, %{}}}}] = Unique.lookup({:applet, name})
    end)

    :ok = Applet.stop!(name)
  end
end
