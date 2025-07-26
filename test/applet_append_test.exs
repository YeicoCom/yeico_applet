defmodule AppletAppendTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  test "append to file" do
    File.write!("/tmp/.exunit_append", "")
    Api.append("/tmp/.exunit_append", "line1\n")
    Api.append("/tmp/.exunit_append", "line2")
    "line1\nline2" = File.read!("/tmp/.exunit_append")
  end
end
