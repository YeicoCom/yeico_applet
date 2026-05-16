defmodule AppletReceiveTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "receive test" do
    dt = NaiveDateTime.utc_now()
    send(self(), {:message, dt})
    {:message, ^dt} = Api.receive()
  end
end
