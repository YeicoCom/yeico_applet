defmodule Applet.Api.Net do
  def hip(hostname) when is_binary(hostname) do
    with {:ok, [{a, b, c, d} | _]} <- DNS.resolve(hostname) do
      {:ok, "#{a}.#{b}.#{c}.#{d}"}
    end
  end

  def nip(nic) when is_binary(nic) do
    nic = to_charlist(nic)

    with {:ok, list} <- :net.getifaddrs(),
         {a, b, c, d} <-
           Enum.find_value(list, nil, fn
             %{name: ^nic, addr: %{addr: {a, b, c, d}}} -> {a, b, c, d}
             _ -> nil
           end) do
      "#{a}.#{b}.#{c}.#{d}"
    end
  end
end
