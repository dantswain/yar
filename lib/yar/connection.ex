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

  def recv(pid, timeout \\ 5000) do
    GenServer.call(pid, :recv, timeout)
  end

  # GenServer callbacks

  def init({host, port}) do
    sock = Socket.TCP.connect!(host, port, packet: :raw)
    {:ok, %{socket: sock}}
  end

  def handle_call({:send, data}, _from, state) do
    Socket.Stream.send!(state[:socket], data)
    {:reply, :ok, state}
  end

  def handle_call(:recv, _from, state) do
    {:reply, do_recv(state[:socket], ""), state}
  end

  # local functions

  defp do_recv(sock, resp) do
    piece = Socket.Stream.recv!(sock)
    new_resp = resp <> piece
    if YAR.RESP.complete_response?(new_resp) do
      new_resp
    else
      do_recv(sock, new_resp)
    end
  end
end
