defmodule AppletTest do
  use ExUnit.Case
  doctest Applet

  test "greets the world" do
    assert Applet.hello() == :world
  end
end
