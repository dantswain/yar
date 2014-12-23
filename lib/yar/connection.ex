defmodule YAR.Connection do
  use GenServer

  @moduledoc """
  Socket connection state helper.
  """

  def start_link(host, port) do
    GenServer.start_link(__MODULE__, {host, port})
  end

  def send_sync(pid, data) do
    GenServer.call(pid, {:send, data})
  end

  def recv(pid, times) do
    GenServer.call(pid, {:recv, times})
  end

  # GenServer callbacks

  def init({host, port}) do
    sock = Socket.TCP.connect!(host, port, packet: :line)
    {:ok, sock}
  end

  def handle_call({:send, data}, _from, sock) do
    Socket.Stream.send!(sock, data)
    {:reply, :ok, sock}
  end

  def handle_call({:recv, times}, _from, sock) do
    {:reply, do_recv(sock, times, ""), sock}
  end

  # local functions

  defp do_recv(_sock, 0, resp), do: resp
  defp do_recv(sock, times, resp) do
    piece = Socket.Stream.recv!(sock)
    do_recv(sock, times - 1, resp <> piece)
  end
end
