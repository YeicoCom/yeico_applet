defmodule Applet.Api.Log do
  def trace(msg), do: Applet.Api.log(:trace, msg)
  def debug(msg), do: Applet.Api.log(:debug, msg)
  def info(msg), do: Applet.Api.log(:info, msg)
  def warn(msg), do: Applet.Api.log(:warn, msg)
  def error(msg), do: Applet.Api.log(:error, msg)
end
