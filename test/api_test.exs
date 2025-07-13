defmodule AppletApiTest do
  use ExUnit.Case, async: false
  use Applet.Api

  test "applet paths with extension" do
    Process.put(:__api__, fn :route -> "dir/file.exs" end)
    assert "dir/sub/lib.exs" == Api.relative("sub/lib.exs")
    assert "dir/lib.exs" == Api.relative("lib.exs")
    assert "dir/file.exs" == Api.route()
    assert "file.exs" == Api.file()
    assert "file" == Api.name()
  end

  test "applet paths without extension" do
    Process.put(:__api__, fn :route -> "dir/file" end)
    assert "dir/sub/lib.exs" == Api.relative("sub/lib.exs")
    assert "dir/lib.exs" == Api.relative("lib.exs")
    assert "dir/file" == Api.route()
    assert "file" == Api.file()
    assert "file" == Api.name()
  end
end
