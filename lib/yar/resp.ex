defmodule YAR.RESP do
  @moduledoc """
  Implementation of the Redis Serialization Protocol (RESP).

  The [Redis Serialization Protocol (RESP)](http://redis.io/topics/protocol)
  is the protocol that clients use to communicate with Redis.

  These functions are used by the main YAR module to construct
  stream data to send to Redis and to decode the responses.
  """

  def parse_command(s) when is_binary(s) do
    from_array(String.split(s))
  end
  def parse_command(s) when is_list(s) do
    if is_deep_list?(s) do
      from_array(s)
    else
      from_binary(s)
    end
  end

  def from_binary(s) do
    s
    |> Enum.map(&maybe_split/1)
    |> List.flatten
    |> from_array
  end

  def from_array(a) do
    elements = length(a)
    from_array(a, "*#{elements}\r\n")
  end

  def parse_response_header("+" <> _rest), do: {:raw_string, 1}
  def parse_response_header("-" <> _rest), do: {:error, 1}
  def parse_response_header(":" <> _rest), do: {:integer, 1}
  def parse_response_header("$" <> _rest), do: {:string, 2}
  def parse_response_header("*" <> rest) do
    num_elements = rest
    |> String.split("\r\n")
    |> List.first
    |> String.to_integer
    {:array, 2 * num_elements + 1}
  end

  def parse_response({:array, raw_string}) do
    parts = String.split(raw_string, "\r\n")
    [_h | t] = Enum.take_every(parts, 2)
    t
  end
  def parse_response({:integer, ":" <> rest}) do
    rest
    |> String.strip
    |> String.to_integer
  end
  def parse_response({:raw_string, "+" <> rest}) do
    String.strip(rest)
  end
  def parse_response({:string, raw_string}) do
    parts = String.split(raw_string, "\r\n")
    tail_head(parts)
  end
  def parse_response({:error, "-ERR" <> error}) do
    {:error, String.strip(error)}
  end

  def parse_subscription_message(msg) do
    msg
    |> String.split("\r\n")
    |> next_to_last
  end

  defp from_array([], so_far), do: so_far
  defp from_array([h | t], so_far) do
    length = sending_length(h)
    from_array(t, so_far <> "$#{length}\r\n#{h}\r\n")
  end

  defp tail_head([_h |t]), do: hd(t)

  defp next_to_last(l), do: :lists.nth(length(l) - 1, l)

  defp maybe_split(s) when is_binary(s), do: String.split(s)
  defp maybe_split(s), do: s

  defp sending_length(s) when is_binary(s), do: String.length(s)
  defp sending_length(s) when is_list(s), do: length(s)
  defp sending_length(s) when is_integer(s), do: 1

  defp is_deep_list?(l = [h | _t]) when is_list(l) do
    is_list(h)
  end
  defp is_deep_list?(_l), do: false
end
