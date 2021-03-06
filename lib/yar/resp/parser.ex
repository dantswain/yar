defmodule YAR.RESP.Parser do
  defmodule State do
    defstruct result: [], string: "", complete: false, num_elements: :infinite

    def update(s = %State{result: previous}, new_string, new_parts)
      when is_list(new_parts) do
      %State{s | string: new_string, result: previous ++ new_parts}
    end
    def update(s, new_string, new_part) do
      update(s, new_string, [new_part])
    end

    def complete(s) do
      %State{s | complete: true}
    end

    def complete?(%State{complete: true}), do: true
    def complete?(%State{complete: false}), do: false

    def append(s = %State{string: existing_string}, new_string) do
      %State{s | string: existing_string <> new_string}
    end
  end

  @type parser_state :: %State{}
  @type parse_result :: {:raw_string, String.t} |
                        {:error, String.t} |
                        {:integer, integer} |
                        {:string, String.t} |
                        {:array, [parse_result]}

  @spec new(String.t, integer) :: parser_state
  def new(string, num_elements) do
    %State{string: string, num_elements: num_elements}
  end

  @spec results(parser_state) :: [parse_result]
  def results(%State{result: result}), do: Enum.reverse(result)

  @spec append_parse(parser_state, String.t) :: parser_state
  def append_parse(s, new_string) do
    s
    |> State.append(new_string)
    |> maybe_do_parse
  end

  @spec complete?(parser_state) :: boolean
  def complete?(s), do: State.complete?(s)

  defp maybe_do_parse(s = %State{string: string}) do
    if String.ends_with?(string, "\r\n") do
      do_parse(s)
    else
      s
    end
  end

  defp do_parse(s = %State{result: result, num_elements: num_elements})
  when length(result) == num_elements do
    if s.string == "" || s.string == "\r\n" do
      State.complete(s)
    else
      s
    end
  end
  defp do_parse(s = %State{string: ""}) do
    if length(s.result) == s.num_elements do
      State.complete(s)
    else
      s
    end
  end
  defp do_parse(s = %State{string: "\r\n" <> remainder}) do
    do_parse(%State{s | string: remainder})
  end
  defp do_parse(s = %State{string: "+" <> rest}) do
    [string, remainder] = chunk(rest)

    s
    |> State.update(remainder, {:raw_string, string})
    |> do_parse
  end
  defp do_parse(s = %State{string: "-" <> rest}) do
    [string, remainder] = chunk(rest)
    s
    |> State.update(remainder, {:error, string})
    |> do_parse
  end
  defp do_parse(s = %State{string: ":" <> rest}) do
    [string, remainder] = chunk(rest)
    s
    |> State.update(remainder, {:integer, String.to_integer(string)})
    |> do_parse
  end
  defp do_parse(s = %State{string: "$" <> rest}) do
    [string, remainder] = chunk(rest)
    length = String.to_integer(string)

    case try_string_split(remainder, length) do
      :fail ->
        s
      {string_out, remainder} ->
        s
        |> State.update(remainder, {:string, string_out})
        |> do_parse
    end
  end
  defp do_parse(s = %State{string: "*" <> rest}) do
    [string, remainder] = chunk(rest)
    num_elements = String.to_integer(string)

    sub_state = %State{string: remainder, num_elements: num_elements}
    %State{string: remainder, result: sub_parts} = do_parse(sub_state)

    s
    |> State.update(remainder, {:array, sub_parts})
    |> do_parse
  end

  defp try_string_split(remainder, length) when byte_size(remainder) < length do
    :fail
  end
  defp try_string_split(remainder, length) do
    << string_out :: binary-size(length), remainder :: binary >> = remainder
    if byte_size(string_out) == length do
      {string_out, remainder}
    else
      :fail
    end
  end

  defp chunk(s) do
    String.split(s, "\r\n", parts: 2)
  end
end
