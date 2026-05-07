defmodule AppletDeferTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "stops waits for defers" do
    assert :ok == Shared.reset()
    assert :ok == Adb.reset()
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      Api.evals("#{route}/defer", """
        use Applet.Api
        # check it is registered under entry and not route
        applet_pid = self()
        defer_pid = Api.defer(fn ->
          Api.sleep(500)
          Log.info("defered")
        end)
        Adb.put("defer:#{route}", {applet_pid, defer_pid})
      """)

      Api.sleep()
    end)

    Tester.assert_starts_with(route, :info, "Applet starting: #{route}")
    Tester.assert_starts_with(route, :info, "#{route}/defer:")
    spawn(fn -> Tester.run(route, fn -> Log.info("restarted") end) end)
    Tester.assert_starts_with(route, :info, "Applet exited: #{route}")
    # IO.inspect(Multiple.list())
    # IO.inspect(Multiple.lookup({:applet_defer, route}))
    {applet_pid, defer_pid} = Adb.get("defer:#{route}")
    assert {defer_pid, applet_pid} in Multiple.lookup({:applet_defer, route})
    Tester.assert_starts_with(route, :info, "defered")
    Tester.assert_starts_with(route, :info, "Applet starting: #{route}")
    Tester.assert_starts_with(route, :info, "restarted")
  end
end
