defmodule Applet.Api.Udb do
  def child_spec(_) do
    Registry.child_spec(keys: :unique, name: __MODULE__)
  end

  def register!(key, value) do
    {:ok, _} = Registry.register(__MODULE__, key, value)
  end

  def update!(key, value) do
    {^value, _} = Registry.update_value(__MODULE__, key, fn _ -> value end)
  end

  def lookup(key) do
    Registry.lookup(__MODULE__, key)
  end

  def list() do
    # {key, pid, args}
    matcher = {:"$1", :"$2", :"$3"}
    selector = [{{:"$1", :"$2", :"$3"}}]
    Registry.select(__MODULE__, [{matcher, [], selector}])
  end
end
