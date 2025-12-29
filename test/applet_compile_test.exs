defmodule Applet.CompileTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "compile error undefined function" do
    route = Tester.route(__MODULE__)
    Tester.run(route, "fun()")
    Tester.assert_starts_with(route, :error, "#{route}:1 compile error undefined function fun/0")
  end

  test "compile error undefined variable" do
    route = Tester.route(__MODULE__)
    Tester.run(route, "fun.()")
    Tester.assert_starts_with(route, :error, "#{route}:1 compile error undefined variable \"fun\"")
  end

  test "compile warning unused variable" do
    route = Tester.route(__MODULE__)
    Tester.run(route, "fn a -> 1 end")
    Tester.assert_starts_with(route, :warn, "#{route}:1 compile warning variable \"a\" is unused")
  end
end
