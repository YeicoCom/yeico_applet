defmodule Applet.Api.Udp do
  alias Applet.Api.Ip4

  # sockname and peername fail on closed socket
  def connect(ip, port, opts \\ []) do
    ip = if is_binary(ip), do: Ip4.parse(ip), else: ip
    active = Keyword.get(opts, :active, false)
    opts = [:binary, active: active]

    with {:ok, socket} <- :gen_udp.open(0, opts),
         :ok <- :gen_udp.connect(socket, ip, port),
         {:ok, {ip, port}} <- :inet.sockname(socket),
         {:ok, {pip, pport}} <- :inet.peername(socket) do
      peer = %{ip: Ip4.tos(pip), port: pport}
      {:ok, %{ip: Ip4.tos(ip), port: port, socket: socket, peer: peer}}
    end
  end

  def listen(ip, port, opts \\ []) do
    active = Keyword.get(opts, :active, false)
    ip = if is_binary(ip), do: Ip4.parse(ip), else: ip
    opts = [:binary, ip: ip, active: active, reuseaddr: true]

    with {:ok, socket} <- :gen_udp.open(port, opts),
         {:ok, {ip, port}} <- :inet.sockname(socket) do
      {:ok, %{ip: Ip4.tos(ip), port: port, socket: socket}}
    end
  end

  def read(%{socket: socket}, toms \\ :infinity) do
    case :gen_udp.recv(socket, 0, toms) do
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

  def owner(%{socket: socket}, %Task{pid: pid}) do
    :gen_udp.controlling_process(socket, pid)
  end

  def owner(%{socket: socket}, pid) do
    :gen_udp.controlling_process(socket, pid)
  end

  def close(%{socket: socket}) do
    :gen_udp.close(socket)
  end
end
