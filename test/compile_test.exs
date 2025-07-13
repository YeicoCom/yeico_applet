defmodule AppletCompileTest do
  use ExUnit.Case, async: false

  test "unused variable warning" do
    {_, [%{message: message}]} =
      Code.with_diagnostics(fn ->
        try do
          Code.eval_string("f = fn a -> 1 end", [], file: "test.exs")
        rescue
          error -> error
        end
      end)

    assert message =~ "variable \"a\" is unused"
  end

  test "undefined variable error" do
    {error, [%{message: message}]} =
      Code.with_diagnostics(fn ->
        try do
          Code.eval_string("a", [], file: "test.exs")
        rescue
          error -> error
        end
      end)

    assert message =~ "undefined variable \"a\""
    assert error.__struct__ == CompileError
  end

  test "match error" do
    {error, []} =
      Code.with_diagnostics(fn ->
        try do
          Code.eval_string("1 = 3", [], file: "test.exs")
        rescue
          error -> error
        end
      end)

    assert error.__struct__ == MatchError
  end

  test "undefined function error" do
    {error, [%{message: message}]} =
      Code.with_diagnostics(fn ->
        try do
          Code.eval_string("is_nil()", [], file: "test.exs")
        rescue
          error -> error
        end
      end)

    assert message =~ "undefined function is_nil/0"
    assert error.__struct__ == CompileError
  end
end
