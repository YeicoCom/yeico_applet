defmodule AppletSigilHTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  test "sigil_H applet" do
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

    Run.applet(code, fn %{pid: pid, route: route} ->
      Wait.success(fn ->
        assert [{^pid, {%Phoenix.LiveView.Rendered{}, %{}}}] =
                 Unique.lookup({:applet, route})
      end)
    end)
  end
end
