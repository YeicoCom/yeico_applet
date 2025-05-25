defmodule AppletTest do
  use ExUnit.Case
  doctest Applet

  test "start" do
    assert Applet.start("name", "") == :ok
  end
end
