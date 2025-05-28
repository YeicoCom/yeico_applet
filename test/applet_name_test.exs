defmodule AppletNameTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  import Eventually

  setup do
    eventually(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "name applet" do
    name = "name"
    code = "
      use Applet.Api

      #{name} = Api.name()
    "

    {:ok, pid} = Applet.start!(name, code)

    eventually(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    eventually(20, 20, fn ->
      assert [{^pid, {:ok, {^name, %{}}}}] = Unique.lookup({:applet, name})
    end)

    :ok = Applet.stop!(name)
  end
end
