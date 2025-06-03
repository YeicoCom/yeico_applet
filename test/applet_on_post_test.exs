defmodule AppletOnPostTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Utils.wait_success(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "on_post applet" do
    name = "on_post"

    code = """
    use Applet.Api

    Api.on(:topic, &Adb.update(:topic, 0, fn c -> c + &1 end))
    Api.post(:topic, 0)
    Api.post(:topic, 1)
    Api.post(:topic, 2)
    Api.post(:topic, 3)

    :ok
    """

    {:ok, pid} = Applet.start!(name, code)

    Utils.wait_success(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    Utils.wait_success(20, 20, fn ->
      assert [{^pid, {:ok, {:ok, %{}}}}] = Unique.lookup({:applet, name})
    end)

    Utils.wait_success(20, 20, fn -> assert 6 = Adb.get(:topic) end)

    :ok = Applet.stop!(name)
  end
end
