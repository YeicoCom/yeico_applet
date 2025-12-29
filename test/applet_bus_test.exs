defmodule Applet.BusTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "bus subscribe/broadcast with args" do
    Bus.subscribe!(:event, :sarg)
    Task.async(fn -> Bus.broadcast!(:event, :barg) end)
    assert :event == (receive do {:event, :sarg, :barg} -> :event end)
  end

  test "bus subscribe/broadcast without args" do
    Bus.subscribe!(:event)
    Task.async(fn -> Bus.broadcast!(:event) end)
    assert :event == (receive do {:event, nil, nil} -> :event end)
  end
end
