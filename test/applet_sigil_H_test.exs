defmodule AppletSigilHTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  setup do
    Utils.wait_success(20, 20, fn -> assert [] = Multiple.list() end)
  end

  test "sigil_H applet" do
    name = "sigil_H"

    code = """
    use Applet.Api

    render = fn assigns ->
      ~H\"""
      {@count}
      \"""
    end

    render.(%{count: 1})
    """

    {:ok, pid} = Applet.start!(name, code)

    Utils.wait_success(20, 20, fn -> assert [{^pid, ^name}] = Multiple.lookup(:applet) end)

    Utils.wait_success(20, 20, fn ->
      assert [{^pid, {:ok, {%Phoenix.LiveView.Rendered{}, %{}}}}] = Unique.lookup({:applet, name})
    end)

    :ok = Applet.stop!(name)
  end
end
