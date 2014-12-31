defmodule YAR do
  @moduledoc File.read!("README.md")
  
  @default_host "localhost"
  @default_port 6379

  @type key_t :: String.t
  @type value_t :: String.t | number
  @type command_t :: String.t | [command_t]
  @type response_t :: String.t | integer | {:error, String.t} | [response_t]

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
    execute_raw_sync(connection, resp_data)
    |> YAR.RESP.map_return
  end

  @doc """
  Pipeline commands to Redis.

  No string interpolation is performed.  Results are returned as an array
  in order matching the commands.
  """
  @spec pipeline(pid, [YAR.command_t]) :: [YAR.response_t]
  def pipeline(connection, commands) do
    resp_data = Enum.map(commands, &YAR.RESP.parse_command/1)
    execute_pipeline(connection, resp_data, length(commands))
    |> YAR.RESP.map_return
    |> Enum.reverse
  end

  @doc """
  Redis `GET key`

  String interpolation is used for `key`.
  """
  @spec get(pid, YAR.key_t) :: YAR.response_t
  def get(connection, key) do
    execute(connection, ["GET", "#{key}"])
  end

  @doc """
  Redis `SET key value`

  String interpolation is used for `key` and `value`.
  """
  @spec set(pid, YAR.key_t, YAR.value_t) :: String.t
  def set(connection, key, value) do
    execute(connection, ["SET", "#{key}", "#{value}"])
  end

  @doc """ 
  Redis `MSET keys_values`

  No string interpolation is performed.  `keys_values` is
  interleaved as in the syntax to MSET, e.g.,
  `YAR.mset(c, ["FOO", "FOOVALUE", "BAR", "BARVALUE"])`.
  """
  @spec mset(pid, [String.t]) :: String.t
  def mset(connection, keys_values) do
    execute(connection, ["MSET"] ++ keys_values)
  end

  @doc """
  Redis `MGET keys`

  No string interpolation is performed on `keys`.
  """
  @spec mget(pid, [String.t]) :: [String.t]
  def mget(connection, keys) do
    execute(connection, ["MGET"] ++ keys)
  end

  @doc """
  Subscribe to a set of routing keys.

  Messages are delivered to the receiver pid as tuples
  of the form `{:yarsub, "message"}`.
  """
  @spec subscribe(pid, [String.t], String.t, pos_integer) :: GenServer.on_start
  def subscribe(receiver, keys, host \\ @default_host, port \\ @default_port) do
    {:ok, connection} = YAR.connect(host, port)
    YAR.Subscriber.start_link(connection, keys, receiver)
  end

  defp execute_raw_sync(connection, data) do
    YAR.Connection.send_sync(connection, data)
    YAR.Connection.recv(connection)
  end

  defp execute_pipeline(connection, data, num_commands) do
    YAR.Connection.send_sync(connection, data)
    YAR.Connection.recv_array(connection, num_commands)
  end
end
