defmodule Applet.EnvironTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "path" do
    pwd = System.get_env("PWD")
    path = "#{pwd}/test/applets"
    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> Api.path() end)
    Tester.assert_starts_with(route, :info, "Applet starting: #{route}")
    Tester.assert_starts_with(route, :info, "#{route}: #{path}")
  end

  test "load" do
    assert ":ok\n" = Applet.load!("ok.exs")

    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> Api.load!("ok.exs") end)
    Tester.assert_starts_with(route, :info, "Applet starting: #{route}")
    Tester.assert_starts_with(route, :info, "#{route}: :ok\n")
  end
end
