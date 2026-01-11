defmodule Applet.DynamicTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "tasks supervisor is killed restoring children count" do
    active = DynamicSupervisor.count_children(Dynamic).active
    route = Tester.route(__MODULE__)
    pid = self()
    Tester.run(route, fn -> send(pid, :inside) end)

    assert :inside ==
             (receive do
                :inside -> :inside
              end)

    assert active + 2 == DynamicSupervisor.count_children(Dynamic).active
    assert 1 == length(Unique.lookup({:applet_super, route}))
    Applet.stop!(route)
    assert 0 == length(Unique.lookup({:applet_super, route}))
    assert active == DynamicSupervisor.count_children(Dynamic).active
  end
end
