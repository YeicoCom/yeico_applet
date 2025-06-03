defmodule AppletWhoamiTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  setup do
    Utils.wait_success(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "whoami applet" do
    route = "_dir/_name.exs"
    code = "
      use Applet.Api

      {Api.path(), Api.route(), Api.name(), Api.file()}
    "

    {:ok, pid} = Applet.start!(route, code)

    path = "#{File.cwd!()}/applets"

    Utils.wait_success(20, 20, fn ->
      assert [{^pid, {{^path, "_dir/_name.exs", "_name", "_name.exs"}, %{}}}] =
               Unique.lookup({:applet, route})
    end)

    Applet.stop!(route)
  end
end
