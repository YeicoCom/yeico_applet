defmodule Applet.Dynamic do
  use DynamicSupervisor

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :args, name: __MODULE__)
  end

  # intensity defaults to 1 and period defaults to 5.
  # meaning: at most 1 restart each 5 seconds
  # https://www.erlang.org/doc/system/sup_princ.html#maximum-restart-intensity
  # [strategy: :one_for_one, intensity: 2, period: 1]
  # https://www.erlang.org/doc/system/sup_princ.html#child-specification
  # restart:
  #   :permanent (always restarted) DEFAULT
  #   :temporary (never restarted)
  #   :transient (restarted if abnormal)
  def init(:args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(spec) do
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def terminate_child(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def which_children() do
    # dynamic supervisor returns undefined id
    DynamicSupervisor.which_children(__MODULE__)
  end
end
