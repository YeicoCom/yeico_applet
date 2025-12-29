defmodule Applet.WrapTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "wrap log" do
    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> spawn(Api.wrap(fn -> Api.warn("oops") end)) end)
    Tester.assert_starts_with(route, :warn, "oops")
  end

  test "wrap unhandled rescue" do
    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> spawn(Api.wrap(fn -> raise "oops" end)) end)
    Tester.assert_starts_with(route, :debug, "UNHANDLED rescue error %RuntimeError{")
    Tester.assert_starts_with(route, :trace, "UNHANDLED rescue stack [")
  end

  test "wrap unhandled catch" do
    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> spawn(Api.wrap(fn -> throw "oops" end)) end)
    Tester.assert_starts_with(route, :debug, "UNHANDLED catch error \"oops\"")
    Tester.assert_starts_with(route, :trace, "UNHANDLED catch stack [")
  end
end
