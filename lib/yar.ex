defmodule YAR do
  @default_host "localhost"
  @default_port 6379

  def connect(host \\ @default_host, port \\ @default_port) do
    YAR.Connection.start_link(host, port)
  end

  def execute(connection, string) do
    resp_data = YAR.RESP.parse_command(string)
    resp_response = execute_raw_sync(connection, resp_data)
    YAR.RESP.parse_response(resp_response)
  end

  def execute_raw_sync(connection, data) do
    YAR.Connection.send_sync(connection, data)
    header = raw_recv(connection, 1)
    {resp_type, num_lines} = YAR.RESP.parse_response_header(header)
    {resp_type, header <> raw_recv(connection, num_lines - 1)}
  end

  def raw_recv(_connection, 0), do: ""
  def raw_recv(connection, num_lines) do
    YAR.Connection.recv(connection, num_lines)
  end
end
