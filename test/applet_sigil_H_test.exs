defmodule AppletSigilHTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  setup do
    Applet.reset!()
  end

  test "sigil_H applet" do
    route = "sigil_H"

    code = """
    use Applet.Api
    use Applet.Api.Live

    render = fn assigns ->
      ~H\"""
      {@count}
      \"""
    end

    render.(%{count: 1})
    """

    {:ok, pid} = Applet.start!(route, code)

    Utils.wait_success(20, 20, fn ->
      assert [{^pid, {%Phoenix.LiveView.Rendered{}, %{}}}] =
               Unique.lookup({:applet, route})
    end)

    Applet.stop!(route)
  end
end
