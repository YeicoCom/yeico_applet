defmodule Applet.Api.Bus do
  def child_spec(_) do
    Registry.child_spec(keys: :duplicate, name: __MODULE__)
  end

  def subscribe(event, sargs \\ nil) do
    Registry.register(__MODULE__, event, sargs)
  end

  def subscribe!(event, sargs \\ nil) do
    {:ok, _} = subscribe(event, sargs)
  end

  def unsubscribe(event) do
    Registry.unregister(__MODULE__, event)
  end

  def broadcast(event, bargs \\ nil) do
    Registry.dispatch(__MODULE__, event, fn entries ->
      for {pid, sargs} <- entries, do: send(pid, {event, sargs, bargs})
    end)
  end

  def broadcast!(event, bargs \\ nil) do
    :ok = broadcast(event, bargs)
  end
end
