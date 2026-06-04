defmodule AppletAsyncTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "async and defer get tagged" do
    route = Tester.route(__MODULE__)
    tag = "--tag--"
    parent = self()

    Tester.run(route, fn ->
      par = self()
      send(parent, {:parent, par})

      %{pid: pid} =
        Api.async(
          fn ->
            dip = Api.defer(fn -> nil end, before: fn -> send(parent, {:before, self()}) end)
            send(parent, {:defer, dip})
            Api.sleep()
          end,
          tag: tag
        )

      send(parent, {:async, pid})
      :ok
    end)

    Tester.assert_starts_with(route, :info, "Applet starting: #{route}")
    Tester.assert_starts_with(route, :info, "#{route}: :ok")
    par = receive do: ({:parent, par} -> par)
    pid = receive do: ({:async, pid} -> pid)
    dip = receive do: ({:defer, dip} -> dip)
    ^dip = receive do: ({:before, dip} -> dip)
    assert {pid, tag: tag, par: par} in Multiple.lookup({:applet_async, route})
    # flaky: this may not be ready -> before ensures it is ready
    assert {dip, tag: tag, mon: pid} in Multiple.lookup({:applet_defer, route})
  end
end
