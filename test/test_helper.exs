ExUnit.start()
Applet.start()

defmodule Tester do
  import ExUnit.Assertions
  require Logger

  def route(prefix) do
    route = "#{prefix}_#{abs(System.monotonic_time(:nanosecond))}.exs"
    Applet.subscribe!(:trace, route)
    route
  end

  def run(route, code) when is_binary(code) do
    Applet.start()
    Applet.start!(route, code: code)
  end

  def run(route, fun) when is_function(fun, 0) do
    Applet.start()
    Applet.start!(route, code: "fun.()", argv: [fun: fun])
  end

  def assert_starts_with(route, level, prefix, toms \\ 1_000) do
    receive do
      {{:logger, ^route, ^level}, sarg, barg} ->
        assert is_nil(sarg)
        assert String.starts_with?(barg, prefix)
      after toms ->
        Logger.warning(timeout: route, level: level, messages: Process.info(self(), :messages))
        throw {:timeout, toms}
    end
  end
end
