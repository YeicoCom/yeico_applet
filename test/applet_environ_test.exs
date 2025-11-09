defmodule AppletEvironTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  test "environ" do
    code = """
    use Applet.Api
    Adb.put(:path, Api.path())
    Adb.put(:route, Api.route())
    """

    home = System.get_env("HOME")
    path = "#{home}/yeico_applet/test/applets"

    Run.applet(code, fn %{route: route, name: _name} ->
      Wait.success(fn -> assert path == Adb.get(:path) end)
      Wait.success(fn -> assert route == Adb.get(:route) end)
    end)
  end
end
