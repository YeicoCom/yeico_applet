defmodule Applet.Api.Bus do
  def child_spec(_) do
    Registry.child_spec(keys: :duplicate, name: __MODULE__)
  end

  def subscribe(event, rargs \\ nil) do
    Registry.register(__MODULE__, event, rargs)
  end

  def subscribe!(event, rargs \\ nil) do
    {:ok, _} = subscribe(event, rargs)
  end

  def unsubscribe(event) do
    Registry.unregister(__MODULE__, event)
  end

  def broadcast(event, dargs \\ nil) do
    Registry.dispatch(__MODULE__, event, fn entries ->
      for {pid, rargs} <- entries, do: send(pid, {event, rargs, dargs})
    end)
  end

  def broadcast!(event, dargs \\ nil) do
    :ok = broadcast(event, dargs)
  end
end
