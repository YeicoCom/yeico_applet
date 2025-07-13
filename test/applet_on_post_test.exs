defmodule AppletOnPostTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  test "on_post applet" do
    code = """
    use Applet.Api

    Api.on(:topic, fn v ->
      Adb.update(:topic, 0, fn c -> c + v end)
      case v do
        0 -> throw :stone
        1 -> raise "child"
        _ -> :ok
      end
    end)
    Api.post(:topic, 0)
    Api.post(:topic, 1)
    Api.post(:topic, 2)
    Api.post(:topic, 3)
    """

    Run.applet(code, fn _ ->
      Wait.success(fn -> assert 6 == Adb.get(:topic) end)
    end)
  end
end
