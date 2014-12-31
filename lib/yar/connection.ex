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

  def recv_array(pid, length, timeout \\ 5000) do
    GenServer.call(pid, {:recv, length}, timeout)
  end

  def recv(pid, timeout \\ 5000) do
    GenServer.call(pid, {:recv, 1}, timeout)
  end

  def sock(pid) do
    GenServer.call(pid, :sock)
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

  def handle_call({:recv, length}, _from, state) do
    {:reply, do_recv(state[:socket], YAR.RESP.Parser.new("", length)), state}
  end

  def handle_call(:sock, _from, state) do
    {:reply, state[:socket], state}
  end

  # local functions

  defp do_recv(sock, parser_state) do
    piece = Socket.Stream.recv!(sock)
    new_state = YAR.RESP.Parser.append_parse(parser_state, piece)
    if YAR.RESP.Parser.complete?(new_state) do
      YAR.RESP.Parser.results(new_state)
    else
      do_recv(sock, new_state)
    end
  end
end
