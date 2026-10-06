defmodule AppletLoopTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "kill loop from top" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      key = "#{__MODULE__}:kill_loop_from_top:count"
      Adb.put(key, 0)
      parent = self()

      task =
        Api.loop(fn ->
          count = Adb.get(key, 0)
          Adb.put(key, count + 1)
          send(parent, {:count, count})

          case count do
            0 -> Process.exit(self(), :kill)
            _ -> Api.sleep()
          end
        end)

      receive do: ({:count, 0} -> nil)
      receive do: ({:count, 1} -> nil)
      Api.kill(task)
      Log.info("killed")
    end)

    Tester.assert_starts_with(route, :info, "Applet starting: #{route}")
    Tester.assert_starts_with(route, :info, "killed")
  end

  test "registration" do
    route = Tester.route(__MODULE__)

    parent = self()

    push = fn tag ->
      send(parent, {tag, self()})
      Api.sleep()
    end

    Tester.run(route, fn ->
      par = self()
      send(parent, {:par, par})
      %{pid: pid} = Api.loop(fn _ -> push.("nil0") end, nil)
      send(parent, {:nil0, pid})
      %{pid: pid} = Api.loop(fn -> push.("nil1") end)
      send(parent, {:nil1, pid})
      %{pid: pid} = Api.loop(fn -> push.("tag0") end, tag: "tag0")
      send(parent, {:tag0, pid})
      %{pid: pid} = Api.loop(fn _ -> push.("tag1") end, nil, tag: "tag1")
      send(parent, {:tag1, pid})
      :ok
    end)

    par = receive do: ({:par, pid} -> pid)
    nil0 = receive do: ({:nil0, pid} -> pid)
    nil1 = receive do: ({:nil1, pid} -> pid)
    tag0 = receive do: ({:tag0, pid} -> pid)
    tag1 = receive do: ({:tag1, pid} -> pid)
    nil0c = receive do: ({"nil0", pid} -> pid)
    nil1c = receive do: ({"nil1", pid} -> pid)
    tag0c = receive do: ({"tag0", pid} -> pid)
    tag1c = receive do: ({"tag1", pid} -> pid)
    Tester.assert_starts_with(route, :info, "Applet starting: #{route}")
    Tester.assert_starts_with(route, :info, "#{route}: :ok")
    assert {nil0, par: par, tag: nil} in Multiple.lookup({:applet_async, route})
    assert {nil1, par: par, tag: nil} in Multiple.lookup({:applet_async, route})
    assert {tag0, par: par, tag: "tag0:super"} in Multiple.lookup({:applet_async, route})
    assert {tag1, par: par, tag: "tag1:super"} in Multiple.lookup({:applet_async, route})
    assert {nil0c, par: nil0, tag: nil} in Multiple.lookup({:applet_async, route})
    assert {nil1c, par: nil1, tag: nil} in Multiple.lookup({:applet_async, route})
    assert {tag0c, par: tag0, tag: "tag0:setup"} in Multiple.lookup({:applet_async, route})
    assert {tag1c, par: tag1, tag: "tag1:setup"} in Multiple.lookup({:applet_async, route})
  end
end
