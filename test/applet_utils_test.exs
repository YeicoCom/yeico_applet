defmodule Applet.UtilsTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "pid and timer infinity" do
    task = Task.async(fn -> Process.sleep(:infinity) end)
    pid = Utils.pid(task)
    assert is_pid(pid)
    assert Process.alive?(pid)
  end

  test "sleep 0" do
    assert :ok == Utils.sleep(0)
  end

  test "hostname both" do
    assert String.starts_with?(Utils.hostname_f(), Utils.hostname())
  end

  test "resolve" do
    assert {:ok, "127.0.0.1"} == Utils.resolve(Utils.hostname())
  end

  test "defer self" do
    self = self()
    spawn(fn -> Utils.defer(fn -> send(self, :defer) end) end)
    assert_receive :defer
  end

  test "defer pid" do
    self = self()
    pid = spawn(fn -> :nop end)
    Utils.defer(pid, fn -> send(self, :defer) end)
    assert_receive :defer
  end

  test "safe 0" do
    assert {:ok, "oops"} == Utils.safe(fn -> "oops" end)
    assert match?({:error, %{type: :rescue, error: %RuntimeError{message: "oops"}, stack: [_ | _]}}, Utils.safe(fn -> raise "oops" end))
    assert match?({:error, %{type: :catch, error: "oops", stack: [_ | _]}}, Utils.safe(fn -> throw "oops" end))
  end

  test "safe 1" do
    assert {:ok, "oops"} == Utils.safe(fn arg -> arg end, "oops")
    assert match?({:error, %{type: :rescue, error: %RuntimeError{message: "oops"}, stack: [_ | _]}}, Utils.safe(fn arg -> raise arg end, "oops"))
    assert match?({:error, %{type: :catch, error: "oops", stack: [_ | _]}}, Utils.safe(fn arg -> throw arg end, "oops"))
  end

  test "kill pid" do
    pid = spawn(fn -> Process.sleep(:infinity) end)
    Utils.kill(pid)
    refute Process.alive?(pid)
  end

  test "kill task" do
    task = Task.async(fn -> Process.sleep(:infinity) end)
    Utils.kill(task)
    refute Process.alive?(task.pid)
  end
end
