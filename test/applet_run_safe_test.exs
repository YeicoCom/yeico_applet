defmodule AppletRunSafeTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "run_safe" do
    assert {:ok, "all good"} = Utils.run_safe(fn -> "all good" end)

    assert {:error, %{type: :rescue, error: %RuntimeError{message: "child"}, stack: stack}} =
             Utils.run_safe(fn -> raise "child" end)

    assert is_list(stack)

    assert {:error, %{type: :catch, error: :stone, stack: stack}} =
             Utils.run_safe(fn -> throw(:stone) end)

    assert is_list(stack)
  end
end
