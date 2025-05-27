defmodule AppletEmptyTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  import Eventually

  setup do
    eventually(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "empty applet" do
    name = "empty"
    code = ""

    {:ok, pid} = Applet.start!(name, code)

    eventually(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    eventually(20, 20, fn ->
      assert [{^pid, {:ok, {nil, %{}}}}] = Unique.lookup({:applet, name})
    end)

    :ok = Applet.stop!(name)
  end
end
