ExUnit.start()
Applet.start()

defmodule Run do
  def applet(code, tests, opts \\ []) do
    use Applet.Api
    route = Keyword.get(opts, :route, "applet_test.exs")
    name = String.trim_trailing(route, ".exs")
    Applet.reset!()
    Adb.reset()
    {:ok, pid} = Applet.start!(route, code)
    tests.(%{pid: pid, route: route, name: name})
    Applet.stop!(route)
  end
end

defmodule Wait do
  alias Applet.Utils

  def success(f) when is_function(f, 0) do
    Utils.wait_success(20, 20, f)
  end
end
