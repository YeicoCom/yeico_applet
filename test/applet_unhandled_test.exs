defmodule AppletUnhandledTest do
  use ExUnit.Case, async: false
  use Applet.Alias
  use Applet.Api

  # https://elixirforum.com/t/how-to-keep-the-code-eval-string-environment-on-async-execution/71285/2
  test "unhandled on async" do
    code = """
    use Applet.Api
    Api.async(fn -> raise "ASYNC" end)
    """

    Applet.subscribe!(:trace, "applet_test.exs", nil)

    Run.applet(code, fn _ ->
      assert_receive {{:logger, "applet_test.exs", :info}, nil, msg}
      assert msg == "Applet starting applet_test.exs"
      assert_receive {{:logger, "applet_test.exs", :debug}, nil, msg}
      assert msg == "UNHANDLED rescue error %RuntimeError{message: \"ASYNC\"}"
      assert_receive {{:logger, "applet_test.exs", :trace}, nil, msg}

      assert msg =~
               "UNHANDLED rescue stack [{:elixir_eval, :__FILE__, 1, [file: ~c\"applet_test.exs\", line: 2]"
    end)
  end

  test "unhandled on async2" do
    code = """
    use Applet.Api
    Api.async(fn -> raise "ASYNC1" end, fn -> raise "ASYNC2" end)
    """

    Applet.subscribe!(:trace, "applet_test.exs", nil)

    Run.applet(code, fn _ ->
      assert_receive {{:logger, "applet_test.exs", :info}, nil, msg}
      assert msg == "Applet starting applet_test.exs"
      assert_receive {{:logger, "applet_test.exs", :debug}, nil, msg}
      assert msg == "UNHANDLED rescue error %RuntimeError{message: \"ASYNC1\"}"
      assert_receive {{:logger, "applet_test.exs", :trace}, nil, msg}

      assert msg =~
               "UNHANDLED rescue stack [{:elixir_eval, :__FILE__, 1, [file: ~c\"applet_test.exs\", line: 2]"

      assert_receive {{:logger, "applet_test.exs", :debug}, nil, msg}
      assert msg == "UNHANDLED rescue error %RuntimeError{message: \"ASYNC2\"}"
      assert_receive {{:logger, "applet_test.exs", :trace}, nil, msg}

      assert msg =~
               "UNHANDLED rescue stack [{:elixir_eval, :__FILE__, 1, [file: ~c\"applet_test.exs\", line: 2]"
    end)
  end

  test "unhandled on defer" do
    code = """
    use Applet.Api
    Api.async(fn -> Api.defer(fn -> raise "DEFER" end) end)
    """

    Applet.subscribe!(:trace, "applet_test.exs", nil)

    Run.applet(code, fn _ ->
      assert_receive {{:logger, "applet_test.exs", :info}, nil, msg}
      assert msg == "Applet starting applet_test.exs"
      assert_receive {{:logger, "applet_test.exs", :debug}, nil, msg}
      assert msg == "UNHANDLED rescue error %RuntimeError{message: \"DEFER\"}"
      assert_receive {{:logger, "applet_test.exs", :trace}, nil, msg}

      assert msg =~
               "UNHANDLED rescue stack [{:elixir_eval, :__FILE__, 1, [file: ~c\"applet_test.exs\", line: 2]"
    end)
  end
end
