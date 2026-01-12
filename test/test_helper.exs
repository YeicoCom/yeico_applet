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
    Applet.start!(route, code: "fun.()", bindings: [fun: fun])
  end

  def assert_starts_with(route, level, prefix, toms \\ 1_000) do
    receive do
      {{:logger, ^route, ^level}, sarg, barg} ->
        assert is_nil(sarg)
        [_route, _pid, msg] = String.split(barg, " ", parts: 3)
        assert String.starts_with?(msg, prefix)
    after
      toms ->
        Logger.warning(timeout: route, level: level, messages: Process.info(self(), :messages))
        throw({:timeout, toms})
    end
  end

  def assert_contains(route, level, substr, toms \\ 1_000) do
    receive do
      {{:logger, ^route, ^level}, sarg, barg} ->
        assert is_nil(sarg)
        [_route, _pid, msg] = String.split(barg, " ", parts: 3)
        assert String.contains?(msg, substr)
    after
      toms ->
        Logger.warning(timeout: route, level: level, messages: Process.info(self(), :messages))
        throw({:timeout, toms})
    end
  end

  def assert_match(route, level, regex, toms \\ 1_000) do
    regex = if is_binary(regex), do: Regex.compile!(regex), else: regex

    receive do
      {{:logger, ^route, ^level}, sarg, barg} ->
        assert is_nil(sarg)
        [_route, _pid, msg] = String.split(barg, " ", parts: 3)
        assert String.match?(msg, regex)
    after
      toms ->
        Logger.warning(timeout: route, level: level, messages: Process.info(self(), :messages))
        throw({:timeout, toms})
    end
  end
end
