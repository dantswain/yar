defmodule YAR.RESP do
  @moduledoc """
  Implementation of the Redis Serialization Protocol (RESP).

  The [Redis Serialization Protocol (RESP)](http://redis.io/topics/protocol)
  is the protocol that clients use to communicate with Redis.

  These functions are used by the main YAR module to construct
  stream data to send to Redis and to decode the responses.
  """

  def parse_command(s) when is_binary(s) do
    pieces = Regex.scan(~r/\w+|"(?:\\"|[^"])+"/, s)
    from_array(List.flatten(pieces))
  end
  def parse_command(s) when is_list(s) do
    from_array(s)
  end

  def from_array(a) do
    elements = length(a)
    from_array(a, "*#{elements}\r\n")
  end

  def map_return([item]), do: map_return(item)
  def map_return({:string, string}), do: string
  def map_return({:raw_string, string}), do: string
  def map_return({:integer, integer}), do: integer
  def map_return({:array, array}) do
    Enum.map(array, &map_return/1)
  end
  def map_return({:error, error}), do: {:error, error}
  def map_return(list) when is_list(list) do
    Enum.map(list, &map_return/1)
  end

  def parse_subscription_message(msg) do
    msg
    |> split
    |> next_to_last
  end

  # TODO: This doesn't really check for a complete response
  def complete_response?(s) do
    String.ends_with?(s, "\r\n")
  end

  defp from_array([], so_far), do: so_far
  defp from_array([h | t], so_far) do
    length = sending_length(h)
    from_array(t, so_far <> "$#{length}\r\n#{h}\r\n")
  end

  defp next_to_last(l), do: :lists.nth(length(l) - 1, l)

  defp sending_length(s) when is_binary(s), do: String.length(s)
  defp sending_length(s) when is_integer(s), do: 1

  defp split(s) do
    String.split(s, "\r\n")
  end
end
