defmodule AppletEvironTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  test "environ" do
    code = """
    use Applet.Api
    Adb.put(:name, Api.name())
    Adb.put(:file, Api.file())
    Adb.put(:path, Api.path())
    Adb.put(:route, Api.route())
    """

    home = System.get_env("HOME")
    path = "#{home}/yeico_applet/test/applets"

    Run.applet(code, fn %{route: route, name: name} ->
      Wait.success(fn -> assert name == Adb.get(:name) end)
      Wait.success(fn -> assert route == Adb.get(:file) end)
      Wait.success(fn -> assert path == Adb.get(:path) end)
      Wait.success(fn -> assert route == Adb.get(:route) end)
    end)
  end
end
