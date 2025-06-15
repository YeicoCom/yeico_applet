defmodule AppletUnhandledTest do
  use ExUnit.Case, async: false
  use Applet.Alias

  setup do
    Applet.reset!()
  end

  # https://elixirforum.com/t/how-to-keep-the-code-eval-string-environment-on-async-execution/71285/2
  test "unhandled on async" do
    route = "unhandled"

    code = """
    use Applet.Api
    Api.async(fn -> raise "ASYNC" end)
    """

    Applet.subscribe!(:trace, "unhandled", nil)
    Applet.start!(route, code)
    assert_receive {{:logger, "unhandled", :info}, nil, msg}
    assert msg == "Applet starting unhandled"
    assert_receive {{:logger, "unhandled", :debug}, nil, msg}
    assert msg == "UNHANDLED rescue error %RuntimeError{message: \"ASYNC\"}"
    assert_receive {{:logger, "unhandled", :trace}, nil, msg}

    assert msg =~
             "UNHANDLED rescue stack [{:elixir_eval, :__FILE__, 1, [file: ~c\"unhandled\", line: 2]"

    Applet.stop!(route)
  end

  test "unhandled on async2" do
    route = "unhandled"

    code = """
    use Applet.Api
    Api.async(fn -> raise "ASYNC1" end, fn -> raise "ASYNC2" end)
    """

    Applet.subscribe!(:trace, "unhandled", nil)
    Applet.start!(route, code)
    assert_receive {{:logger, "unhandled", :info}, nil, msg}
    assert msg == "Applet starting unhandled"
    assert_receive {{:logger, "unhandled", :debug}, nil, msg}
    assert msg == "UNHANDLED rescue error %RuntimeError{message: \"ASYNC1\"}"
    assert_receive {{:logger, "unhandled", :trace}, nil, msg}

    assert msg =~
             "UNHANDLED rescue stack [{:elixir_eval, :__FILE__, 1, [file: ~c\"unhandled\", line: 2]"

    assert_receive {{:logger, "unhandled", :debug}, nil, msg}
    assert msg == "UNHANDLED rescue error %RuntimeError{message: \"ASYNC2\"}"
    assert_receive {{:logger, "unhandled", :trace}, nil, msg}

    assert msg =~
             "UNHANDLED rescue stack [{:elixir_eval, :__FILE__, 1, [file: ~c\"unhandled\", line: 2]"

    Applet.stop!(route)
  end

  test "unhandled on post/on" do
    route = "unhandled"

    code = """
    use Applet.Api
    Api.on(:event, fn msg -> raise msg end)
    Api.post(:event, "MSG1")
    Api.post(:event, "MSG2")
    """

    Applet.subscribe!(:trace, "unhandled", nil)
    Applet.start!(route, code)
    assert_receive {{:logger, "unhandled", :info}, nil, msg}
    assert msg == "Applet starting unhandled"
    assert_receive {{:logger, "unhandled", :debug}, nil, msg}
    assert msg == "UNHANDLED rescue error %RuntimeError{message: \"MSG1\"}"
    assert_receive {{:logger, "unhandled", :trace}, nil, msg}

    assert msg =~
             "UNHANDLED rescue stack [{:elixir_eval, :__FILE__, 1, [file: ~c\"unhandled\", line: 2]"

    assert_receive {{:logger, "unhandled", :debug}, nil, msg}
    assert msg == "UNHANDLED rescue error %RuntimeError{message: \"MSG2\"}"
    assert_receive {{:logger, "unhandled", :trace}, nil, msg}

    assert msg =~
             "UNHANDLED rescue stack [{:elixir_eval, :__FILE__, 1, [file: ~c\"unhandled\", line: 2]"

    Applet.stop!(route)
  end

  test "unhandled on defer" do
    route = "unhandled"

    code = """
    use Applet.Api
    Api.async(fn -> Api.defer(fn -> raise "DEFER" end) end)
    """

    Applet.subscribe!(:trace, "unhandled", nil)
    Applet.start!(route, code)
    assert_receive {{:logger, "unhandled", :info}, nil, msg}
    assert msg == "Applet starting unhandled"
    assert_receive {{:logger, "unhandled", :debug}, nil, msg}
    assert msg == "UNHANDLED rescue error %RuntimeError{message: \"DEFER\"}"
    assert_receive {{:logger, "unhandled", :trace}, nil, msg}

    assert msg =~
             "UNHANDLED rescue stack [{:elixir_eval, :__FILE__, 1, [file: ~c\"unhandled\", line: 2]"

    Applet.stop!(route)
  end
end
