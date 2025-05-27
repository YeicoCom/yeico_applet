defmodule Applet.Api.Tcp do
  def connect(ip, port, opts \\ []) do
    line = Keyword.get(opts, :line, false)
    active = Keyword.get(opts, :active, false)
    packet = if line, do: :line, else: :raw
    opts = [:binary, packet: packet, active: active]
    ip = if is_binary(ip), do: parse(ip), else: ip
    {:ok, socket} = :gen_tcp.connect(ip, port, opts)
    {:ok, {ip, port}} = :inet.sockname(socket)
    {:ok, peer} = :inet.peername(socket)
    {:ok, %{ip: ip, port: port, socket: socket, peer: peer}}
  end

  def listen(ip, port, opts \\ []) do
    line = Keyword.get(opts, :line, false)
    active = Keyword.get(opts, :active, false)
    packet = if line, do: :line, else: :raw
    ip = if is_binary(ip), do: parse(ip), else: ip
    opts = [:binary, ip: ip, packet: packet, active: active, reuseaddr: true]
    {:ok, socket} = :gen_tcp.listen(port, opts)
    {:ok, {ip, port}} = :inet.sockname(socket)
    {:ok, %{ip: ip, port: port, socket: socket}}
  end

  def accept(%{socket: socket}) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, {ip, port}} = :inet.peername(client)
    {:ok, %{ip: ip, port: port, socket: client}}
  end

  def read(%{socket: socket}) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end

  def receive(%{socket: socket}) do
    receive do
      {:tcp, ^socket, data} ->
        {:ok, data}

      {:tcp_closed, ^socket} ->
        {:error, :closed}
    end
  end

  def write(%{socket: socket}, data) do
    :gen_tcp.send(socket, data)
  end

  def owner(%{socket: socket}, pid) do
    :gen_tcp.controlling_process(socket, pid)
  end

  def close(%{socket: socket}) do
    :gen_tcp.close(socket)
  end

  defp parse(ip) do
    :inet.parse_address(~c"#{ip}") |> elem(1)
  end
end
