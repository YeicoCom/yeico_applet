defmodule Applet.Api.Tcp do
  alias Applet.Api.Ip4

  def connect(ip, port, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, :infinity)
    line = Keyword.get(opts, :line, false)
    active = Keyword.get(opts, :active, false)
    packet = if line, do: :line, else: :raw
    opts = [:binary, packet: packet, active: active]
    ip = if is_binary(ip), do: Ip4.parse(ip), else: ip

    with {:ok, socket} <- :gen_tcp.connect(ip, port, opts, timeout) do
      {:ok, {ip, port}} = :inet.sockname(socket)
      {:ok, {pip, pport}} = :inet.peername(socket)
      peer = %{ip: Ip4.tos(pip), port: pport}
      {:ok, %{ip: Ip4.tos(ip), port: port, socket: socket, peer: peer}}
    end
  end

  def listen(ip, port, opts \\ []) do
    line = Keyword.get(opts, :line, false)
    active = Keyword.get(opts, :active, false)
    packet = if line, do: :line, else: :raw
    ip = if is_binary(ip), do: Ip4.parse(ip), else: ip
    opts = [:binary, ip: ip, packet: packet, active: active, reuseaddr: true]

    with {:ok, socket} <- :gen_tcp.listen(port, opts) do
      {:ok, {ip, port}} = :inet.sockname(socket)
      {:ok, %{ip: Ip4.tos(ip), port: port, socket: socket}}
    end
  end

  def accept(%{socket: socket}) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, {ip, port}} = :inet.sockname(client)
    {:ok, {pip, pport}} = :inet.peername(client)
    peer = %{ip: Ip4.tos(pip), port: pport}
    {:ok, %{ip: Ip4.tos(ip), port: port, socket: client, peer: peer}}
  end

  def read(%{socket: socket}, timeout \\ :infinity) do
    case :gen_tcp.recv(socket, 0, timeout) do
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

  def owner(%{socket: socket}, %Task{pid: pid}) do
    :gen_tcp.controlling_process(socket, pid)
  end

  def owner(%{socket: socket}, pid) do
    :gen_tcp.controlling_process(socket, pid)
  end

  def close(%{socket: socket}) do
    :gen_tcp.close(socket)
  end
end
