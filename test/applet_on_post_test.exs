defmodule AppletOnPostTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Applet.reset!()
    Adb.reset()
  end

  test "on_post applet" do
    route = "on_post"

    code = """
    use Applet.Api

    Api.on(:topic, fn v ->
      Adb.update(:topic, 0, fn c -> c + v end)
      case v do
        0 -> throw :stone
        _ -> raise "child"
      end
    end)
    Api.post(:topic, 0)
    Api.post(:topic, 1)
    Api.post(:topic, 2)
    Api.post(:topic, 3)

    :ok
    """

    {:ok, pid} = Applet.start!(route, code)

    Utils.wait_success(20, 20, fn ->
      assert [{^pid, {:ok, %{}}}] = Unique.lookup({:applet, route})
    end)

    Utils.wait_success(20, 20, fn -> assert 6 = Adb.get(:topic) end)

    Applet.stop!(route)
  end
end
