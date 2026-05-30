defmodule Applet.WrapTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "wrap log" do
    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> spawn(Api.wrap(fn -> Log.warn("oops") end)) end)
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
    Tester.run(route, fn -> spawn(Api.wrap(fn -> throw("oops") end)) end)
    Tester.assert_starts_with(route, :debug, "UNHANDLED catch error oops")
    Tester.assert_starts_with(route, :trace, "UNHANDLED catch stack [")
  end

  test "throw shows file reference in stacktrace" do
    route = Tester.route(__MODULE__)
    Tester.run(route, fn -> throw(:OOPS!) end)
    Tester.assert_match(route, :error, "catch: .*:OOPS!.*stack: .*#{route}")
  end

  test "evals throw shows file reference in stacktrace" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      Api.evals("CODE1_EXS", "throw :OOPS1!")
      Api.evals("CODE2_EXS", "throw :OOPS2!")
      throw(:OOPS3!)
    end)

    Tester.assert_match(route, :error, "catch: .*:OOPS1!.*stack: .*CODE1_EXS")
    Tester.assert_match(route, :error, "catch: .*:OOPS2!.*stack: .*CODE2_EXS")
    Tester.assert_match(route, :error, "catch: .*:OOPS3!.*stack: .*#{route}")
  end

  test "api wrap fun 0 context restored after catch" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      {fun1, _} = Api.evals("CODE1_EXS", "fn -> throw :OOPS1! end |> Applet.Api.wrap()")
      {fun2, _} = Api.evals("CODE2_EXS", "fn -> throw :OOPS2! end |> Applet.Api.wrap()")
      Log.error(Api.safe(fun1))
      Log.error(Api.safe(fun2))
      throw(:OOOOPS!)
    end)

    Tester.assert_match(route, :error, "error: :OOPS1!.*stack: .*CODE1_EXS")
    Tester.assert_match(route, :error, "error: :OOPS2!.*stack: .*CODE2_EXS")
    Tester.assert_match(route, :error, "catch: .*OOOOPS!.*stack: .*#{route}")
  end

  test "api wrap fun 1 context restored after catch" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      {fun, _} = Api.evals("CODE_EXS", "fn arg -> throw arg end |> Applet.Api.wrap()")
      Log.error(Api.safe(fun, :OOPS1!))
      Log.error(Api.safe(fun, :OOPS2!))
      throw(:OOOOPS!)
    end)

    Tester.assert_match(route, :error, "error: :OOPS1!.*stack: .*CODE_EXS")
    Tester.assert_match(route, :error, "error: :OOPS2!.*stack: .*CODE_EXS")
    Tester.assert_match(route, :error, "catch: .*OOOOPS!.*stack: .*#{route}")
  end

  test "late wrap fun 0 context restored after catch" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      {fun1, _} =
        Api.evals("CODE1_EXS", "wrap = Applet.Api.wrapper(); fn -> throw :OOPS1! end |> wrap.()")

      {fun2, _} =
        Api.evals("CODE2_EXS", "wrap = Applet.Api.wrapper(); fn -> throw :OOPS2! end |> wrap.()")

      Log.error(Api.safe(fun1))
      Log.error(Api.safe(fun2))
      throw(:OOOOPS!)
    end)

    Tester.assert_match(route, :error, "error: :OOPS1!.*stack: .*CODE1_EXS")
    Tester.assert_match(route, :error, "error: :OOPS2!.*stack: .*CODE2_EXS")
    Tester.assert_match(route, :error, "catch: .*OOOOPS!.*stack: .*#{route}")
  end

  test "late wrap fun 1 context restored after catch" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      {fun, _} =
        Api.evals("CODE_EXS", "wrap = Applet.Api.wrapper(); fn arg -> throw arg end |> wrap.()")

      Log.error(Api.safe(fun, :OOPS1!))
      Log.error(Api.safe(fun, :OOPS2!))
      throw(:OOOOPS!)
    end)

    Tester.assert_match(route, :error, "error: :OOPS1!.*stack: .*CODE_EXS")
    Tester.assert_match(route, :error, "error: :OOPS2!.*stack: .*CODE_EXS")
    Tester.assert_match(route, :error, "catch: .*OOOOPS!.*stack: .*#{route}")
  end

  test "api wrap fun 0 context restored after rescue" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      {fun1, _} = Api.evals("CODE1_EXS", "fn -> raise \"OOPS1!\" end |> Applet.Api.wrap()")
      {fun2, _} = Api.evals("CODE2_EXS", "fn -> raise \"OOPS2!\" end |> Applet.Api.wrap()")
      Log.error(Api.safe(fun1))
      Log.error(Api.safe(fun2))
      raise("OOOOPS!")
    end)

    Tester.assert_match(route, :error, "message: \\\"OOPS1!\\\".*stack: .*CODE1_EXS")
    Tester.assert_match(route, :error, "message: \\\"OOPS2!\\\".*stack: .*CODE2_EXS")
    Tester.assert_match(route, :error, "rescue: .*\\\"OOOOPS!\\\".*stack: .*#{route}")
  end

  test "api wrap fun 1 context restored after rescue" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      {fun, _} = Api.evals("CODE_EXS", "fn arg -> raise arg end |> Applet.Api.wrap()")
      Log.error(Api.safe(fun, "OOPS1!"))
      Log.error(Api.safe(fun, "OOPS2!"))
      raise("OOOOPS!")
    end)

    Tester.assert_match(route, :error, "message: \\\"OOPS1!\\\".*stack: .*CODE_EXS")
    Tester.assert_match(route, :error, "message: \\\"OOPS2!\\\".*stack: .*CODE_EXS")
    Tester.assert_match(route, :error, "rescue: .*\\\"OOOOPS!\\\".*stack: .*#{route}")
  end

  test "late wrap fun 0 context restored after rescue" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      {fun1, _} =
        Api.evals(
          "CODE1_EXS",
          "wrap = Applet.Api.wrapper(); fn -> raise \"OOPS1!\" end |> wrap.()"
        )

      {fun2, _} =
        Api.evals(
          "CODE2_EXS",
          "wrap = Applet.Api.wrapper(); fn -> raise \"OOPS2!\" end |> wrap.()"
        )

      Log.error(Api.safe(fun1))
      Log.error(Api.safe(fun2))
      raise("OOOOPS!")
    end)

    Tester.assert_match(route, :error, "message: \\\"OOPS1!\\\".*stack: .*CODE1_EXS")
    Tester.assert_match(route, :error, "message: \\\"OOPS2!\\\".*stack: .*CODE2_EXS")
    Tester.assert_match(route, :error, "rescue: .*\\\"OOOOPS!\\\".*stack: .*#{route}")
  end

  test "late wrap fun 1 context restored after rescue" do
    route = Tester.route(__MODULE__)

    Tester.run(route, fn ->
      {fun, _} =
        Api.evals("CODE_EXS", "wrap = Applet.Api.wrapper(); fn arg -> raise arg end |> wrap.()")

      Log.error(Api.safe(fun, "OOPS1!"))
      Log.error(Api.safe(fun, "OOPS2!"))
      raise("OOOOPS!")
    end)

    Tester.assert_match(route, :error, "message: \\\"OOPS1!\\\".*stack: .*CODE_EXS")
    Tester.assert_match(route, :error, "message: \\\"OOPS2!\\\".*stack: .*CODE_EXS")
    Tester.assert_match(route, :error, "rescue: .*\\\"OOOOPS!\\\".*stack: .*#{route}")
  end
end
