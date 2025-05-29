defmodule AppletAsyncBusTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  setup do
    Utils.wait_success(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "async/bus applet" do
    name = "async/bus"

    code = """
    use Applet.Api

    Api.async(fn ->
      Bus.subscribe!(:event, :sargs)
      Api.async(fn ->
        Bus.broadcast!(:event, :bargs)
        Api.sleep()
      end)
      receive do
        {:event, :sargs, :bargs} -> :ok
      end
    end) |> Api.await()
    """

    {:ok, pid} = Applet.start!(name, code)

    Utils.wait_success(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    Utils.wait_success(20, 20, fn ->
      assert [{^pid, {:ok, {{:ok, :ok}, %{}}}}] = Unique.lookup({:applet, name})
    end)

    :ok = Applet.stop!(name)
  end
end
