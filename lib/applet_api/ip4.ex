defmodule Applet.Api.Ip4 do
  def tos(ip) when is_binary(ip), do: ip
  def tos({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"

  def parse(ip) do
    :inet.parse_address(~c"#{ip}") |> elem(1)
  end
end
