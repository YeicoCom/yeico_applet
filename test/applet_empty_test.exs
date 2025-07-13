defmodule AppletEmptyTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  test "empty applet" do
    Run.applet("", fn %{pid: pid, route: route} ->
      Wait.success(fn -> assert [{^pid, ^route}] = Multiple.lookup(:applet) end)

      Wait.success(fn ->
        assert [{^pid, {nil, %{}}}] = Unique.lookup({:applet, route})
      end)
    end)
  end
end
