defmodule AppletKillTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "unlinked killed async" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      parent = self()

      %{pid: pid} =
        Api.async(fn ->
          Process.unlink(parent)
          Process.exit(self(), :kill)
        end)

      receive do
        {:DOWN, _, :process, ^pid, :killed} -> Log.info("killed")
      end
    end)

    Tester.assert_starts_with(route, :info, "Applet starting: #{route}")
    Tester.assert_starts_with(route, :info, "killed")
  end

  test "supervised killed async" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      Process.flag(:trap_exit, true)

      %{pid: pid} =
        Api.async(fn ->
          Process.exit(self(), :kill)
        end)

      receive do
        {:DOWN, _, :process, ^pid, :killed} -> Log.info("killed")
      end
    end)

    Tester.assert_starts_with(route, :info, "Applet starting: #{route}")
    Tester.assert_starts_with(route, :info, "killed")
  end
end
