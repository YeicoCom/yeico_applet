defmodule AppletTest do
  use ExUnit.Case
  use Applet.Alias
  use AssertEventually, timeout: 200, interval: 20

  test "start" do
    {:ok, pid} = Applet.start!("name", "1")
    assert_eventually(fn -> assert [{:applet, ^pid, "name"}] = Multiple.list() end)
  end
end
