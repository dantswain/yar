defmodule YAR.RESP do
  def parse_command(s) when is_binary(s) do
    from_array(String.split(s))
  end
  def parse_command(s) when is_list(s) do
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

  defp from_array([], so_far), do: so_far
  defp from_array([h | t], so_far) do
    length = String.length(h)
    from_array(t, so_far <> "$#{length}\r\n#{h}\r\n")
  end

  defp tail_head([_h |t]), do: List.first(t)

  defp maybe_split(s) when is_binary(s), do: String.split(s)
  defp maybe_split(s), do: s
end
