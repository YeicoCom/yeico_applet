defmodule Applet.Api.Udp do
  def connect(ip, port, opts \\ []) do
    active = Keyword.get(opts, :active, false)
    opts = [:binary, active: active]
    {:ok, socket} = :gen_udp.open(0, opts)
    ip = if is_binary(ip), do: parse(ip), else: ip
    :ok = :gen_udp.connect(socket, ip, port)
    {:ok, {ip, port}} = :inet.sockname(socket)
    {:ok, peer} = :inet.peername(socket)
    {:ok, %{ip: ip, port: port, socket: socket, peer: peer}}
  end

  def listen(ip, port, opts \\ []) do
    active = Keyword.get(opts, :active, false)
    ip = if is_binary(ip), do: parse(ip), else: ip
    opts = [:binary, ip: ip, active: active]
    {:ok, socket} = :gen_udp.open(port, opts)
    {:ok, {ip, port}} = :inet.sockname(socket)
    {:ok, %{ip: ip, port: port, socket: socket}}
  end

  def read(%{socket: socket}, timeout \\ :infinity) do
    case :gen_udp.recv(socket, 0, timeout) do
      {:ok, {ip, port, data}} -> {:ok, {ip, port, data}}
      {:error, reason} -> {:error, reason}
    end
  end

  def receive(%{socket: socket}) do
    receive do
      {:udp, ^socket, ip, port, data} ->
        {:ok, {ip, port, data}}

      {:udp_error, ^socket, reason} ->
        {:error, reason}
    end
  end

  def write(%{socket: socket}, data) do
    :gen_udp.send(socket, data)
  end

  def write(%{socket: socket}, ip, port, data) do
    :gen_udp.send(socket, {ip, port}, data)
  end

  def owner(%{socket: socket}, pid) do
    :gen_udp.controlling_process(socket, pid)
  end

  def close(%{socket: socket}) do
    :gen_udp.close(socket)
  end

  defp parse(ip) do
    :inet.parse_address(~c"#{ip}") |> elem(1)
  end
end
