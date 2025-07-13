defmodule AppletEvironTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  setup do
    Applet.reset!()
    Adb.reset()
  end

  test "environ" do
    route = "environ.exs"

    code = """
    use Applet.Api
    Adb.put(:name, Api.name())
    Adb.put(:file, Api.file())
    Adb.put(:path, Api.path())
    """

    home = System.get_env("HOME")
    path = "#{home}/yeico_applet/applets"

    Applet.start!(route, code)
    Wait.success(fn -> assert "environ" == Adb.get(:name) end)
    Wait.success(fn -> assert "environ.exs" == Adb.get(:file) end)
    Wait.success(fn -> assert path == Adb.get(:path) end)
    Applet.stop!(route)
  end
end
