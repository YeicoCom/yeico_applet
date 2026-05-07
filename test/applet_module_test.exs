defmodule Applet.ModuleTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  test "compile warning module redefined" do
    route = Tester.route(__MODULE__)

    Tester.run(route, """
    use Applet.Api
    defmodule Module1 do
    end
    defmodule Module1 do
    end
    Log.warn("done")
    :ok
    """)

    # suppress: redefining module Module1 (current version defined in memory)
    Tester.assert_starts_with(route, :info, "Applet starting: #{route}")
    Tester.assert_starts_with(route, :info, "#{route}: :ok")
    Tester.assert_starts_with(route, :warn, "done")
  end
end
