defmodule Applet.Runner do
  use Applet.Alias

  def start_link(name, code) do
    state = %{name: name, code: code}
    {:ok, spawn_link(fn -> init(state) end)}
  end

  defp init(%{name: name, code: code}) do
    Applet.stop!(name)
    Unique.register!({:applet, name}, nil)
    Multiple.register!(:applet, name)
    # functions only to avoid poluting module space
    # spawn_link only to ensure proper cleanup
    # do not change the pwd or any other environment
    eval = fn -> Code.eval_string(code, [], file: name) end
    result = Utils.run_safe(eval)
    Unique.update!({:applet, name}, result)
    :timer.sleep(:infinity)
  end
end
