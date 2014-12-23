defmodule YAR do
  @moduledoc File.read!("README.md")
  
  @default_host "localhost"
  @default_port 6379

  @type key_t :: iodata
  @type value_t :: iodata | number
  @type command_t :: iodata
  @type response_t :: iodata

  @doc """
  Connect to Redis server at `host:port`.

  On success, returns `{:ok, pid}` where pid is
  the connection process to pass to other YAR calls.
  """
  @spec connect(String.t, integer) :: GenServer.on_start
  def connect(host \\ @default_host, port \\ @default_port) do
    YAR.Connection.start_link(host, port)
  end

  @doc """
  Execute a Redis command.

  The command may be a binary (`"GET FOO"`),
  char list (`'GET FOO'`), or (potentially nested) list of
  binaries (`["GET", "FOO"]`) list.
  """
  @spec execute(pid, YAR.command_t) :: YAR.response_t
  def execute(connection, string) do
    resp_data = YAR.RESP.parse_command(string)
    resp_response = execute_raw_sync(connection, resp_data)
    YAR.RESP.parse_response(resp_response)
  end

  @doc """
  Get the value associated with `key`.

  String interpolation is used for `key`.
  """
  @spec get(pid, YAR.key_t) :: YAR.response_t
  def get(connection, key) do
    execute(connection, ["GET", "#{key}"])
  end

  @doc """
  Set the value associated with `key`.

  String interpolation is used for `key` and `value`.
  """
  @spec set(pid, YAR.key_t, YAR.value_t) :: String.t
  def set(connection, key, value) do
    execute(connection, ["SET", "#{key}", "#{value}"])
  end

  defp execute_raw_sync(connection, data) do
    YAR.Connection.send_sync(connection, data)
    header = raw_recv(connection, 1)
    {resp_type, num_lines} = YAR.RESP.parse_response_header(header)
    {resp_type, header <> raw_recv(connection, num_lines - 1)}
  end

  defp raw_recv(_connection, 0), do: ""
  defp raw_recv(connection, num_lines) do
    YAR.Connection.recv(connection, num_lines)
  end
end
