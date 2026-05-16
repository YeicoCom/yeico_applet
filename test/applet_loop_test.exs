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
        Api.loop(0, fn ->
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
end
