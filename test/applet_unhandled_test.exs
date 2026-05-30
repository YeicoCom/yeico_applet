defmodule Applet.UnhandledTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "applet unhandled raise" do
    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> raise "oops" end)
    Tester.assert_starts_with(route, :error, "#{route} rescue: %RuntimeError{")
  end

  test "applet unhandled throw" do
    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> throw("oops") end)
    Tester.assert_starts_with(route, :error, "#{route} catch: oops")
  end

  test "applet match error" do
    route = Tester.route(__MODULE__)
    Tester.run(route, "1 = 2")
    Tester.assert_starts_with(route, :error, "#{route} rescue: %MatchError{term: 2}")
  end

  test "applet function clause error" do
    route = Tester.route(__MODULE__)
    Tester.run(route, "f = fn 1 -> 2 end; f.(2)")
    Tester.assert_starts_with(route, :error, "#{route} rescue: %FunctionClauseError{")
  end

  test "async unhandled raise" do
    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> Api.async(fn -> raise "oops" end) end)
    Tester.assert_starts_with(route, :debug, "UNHANDLED rescue error %RuntimeError{")
    Tester.assert_starts_with(route, :trace, "UNHANDLED rescue stack [")
  end

  test "async unhandled throw" do
    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> Api.async(fn -> throw("oops") end) end)
    Tester.assert_starts_with(route, :debug, "UNHANDLED catch error oops")
    Tester.assert_starts_with(route, :trace, "UNHANDLED catch stack [")
  end

  test "async unhandled match error" do
    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> Api.async(fn -> 1 = 2 end) end)
    Tester.assert_starts_with(route, :debug, "UNHANDLED rescue error %MatchError{term: 2}")
    Tester.assert_starts_with(route, :trace, "UNHANDLED rescue stack [")
  end

  test "async unhandled function clause error" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      Api.async(fn ->
        f = fn 1 -> 2 end
        f.(2)
      end)
    end)

    Tester.assert_starts_with(route, :debug, "UNHANDLED rescue error %FunctionClauseError{")
    Tester.assert_starts_with(route, :trace, "UNHANDLED rescue stack [")
  end
end
