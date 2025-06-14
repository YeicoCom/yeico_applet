defmodule Applet.Api.Dns do
  def resolve(hostname) when is_binary(hostname) do
    with {:ok, [{a, b, c, d} | _]} <- DNS.resolve(hostname) do
      {:ok, "#{a}.#{b}.#{c}.#{d}"}
    end
  end
end
