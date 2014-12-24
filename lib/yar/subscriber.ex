defmodule YAR.Subscriber do
  use GenServer

  @moduledoc "Pubsub subscriber"

  def start_link(connection, keys, receiver) do
    GenServer.start_link(__MODULE__,
                         {connection, keys, receiver})
  end

  # GenServer callbacks

  def init({connection, keys, receiver}) do
    num_keys = length(keys)
    resp_data = YAR.RESP.parse_command(["SUBSCRIBE", keys])
    YAR.Connection.send_sync(connection, resp_data)
    YAR.Connection.recv(connection, 6 * num_keys)
    {:ok, %{connection: connection, receiver: receiver}, 0}
  end

  def handle_info(:timeout, state) do
    got = YAR.Connection.recv(state[:connection], 7, :infinity)
    msg = YAR.RESP.parse_subscription_message(got)
    send(state[:receiver], {:yarsub, msg})
    {:noreply, state, 0}
  end
end
