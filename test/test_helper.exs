ExUnit.start()

defmodule Eventually do
  use Applet.Alias

  def eventually(period, times, fun) when period > 0 and times > 0 and is_function(fun, 0) do
    last = times - 1

    Stream.interval(period)
    |> Stream.take(times)
    |> Stream.with_index()
    |> Stream.map(fn {_, i} -> {i, Utils.run_safe(fun)} end)
    |> Stream.take_while(fn
      {_, {:error, _}} -> true
      {_, {:ok, _}} -> false
    end)
    |> Stream.take(-1)
    |> Enum.to_list()
    |> case do
      [{^last, {:error, %{error: error, stack: stack}}}] -> reraise(error, stack)
      _ -> :ok
    end
  end
end
