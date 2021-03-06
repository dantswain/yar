defmodule YARTest do
  use ExUnit.Case

  @test_port 5000

  setup do
    {:ok, c} = YAR.connect("localhost", @test_port)
    "OK" = YAR.execute(c, "FLUSHALL")
    {:ok, connection: c}
  end

  test "ping response", %{connection: c} do
    assert "PONG" == YAR.execute(c, "PING")
  end

  test "set/get", %{connection: c} do
    assert "OK" == YAR.execute(c, "SET FOO BAR")
    assert "BAR" == YAR.execute(c, "GET FOO")
  end

  test "integer response to incr", %{connection: c} do
    assert "OK" == YAR.execute(c, "SET FOO 1")
    assert 2 == YAR.execute(c, "INCR FOO")
  end

  test "error response", %{connection: c} do
    assert {:error, "ERR unknown command 'WTFISNOTACOMMAND'"} ==
      YAR.execute(c, "WTFISNOTACOMMAND")
  end

  test "mget array response", %{connection: c} do
    assert "OK" == YAR.execute(c, "SET FOO BANG")
    assert "OK" == YAR.execute(c, "SET BAR BLAM")
    assert ["BANG", "BLAM"] == YAR.execute(c, "MGET FOO BAR")
  end

  test "pass in list", %{connection: c} do
    assert "OK" == YAR.execute(c, ["SET", "FOO", "BAR"])
    assert "BAR" == YAR.execute(c, ["GET", "FOO"])
  end

  test "set/get helpers", %{connection: c} do
    assert "OK" == YAR.set(c, "foo", 42)
    assert "42" == YAR.get(c, "foo")
    assert "42" == YAR.get(c, 'foo')
  end

  test "mset/mget helpers", %{connection: c} do
    assert "OK" == YAR.mset(c, ["FOO", "42", "BAR", "baz"])
    assert ["42", "baz"] == YAR.mget(c, ["FOO", "BAR"])
  end

  test "pipelining", %{connection: c} do
    commands1 = [
                  ["SET", "FOO", "BAR"],
                  ["PING"],
                  ["SET", "BAR", "BAZ"]
              ]
    commands2 = [
                  "GET FOO",
                  ["PING"],
                  ["GET", "BAR"]
              ]
    assert ["OK", "PONG", "OK"] ==  YAR.pipeline(c, commands1)
    assert ["BAR", "PONG", "BAZ"] == YAR.pipeline(c, commands2)
  end

  test "subscribing", %{connection: c} do
    {:ok, _pid} = YAR.subscribe(self, ["foo"], "localhost", @test_port)
    assert 1 == YAR.execute(c, ["PUBLISH", "foo", "bar"])
    assert_receive({:yarsub, "bar"})
  end

  test "handle messages with spaces", %{connection: c} do
    assert "OK" == YAR.set(c, "foo", "bar baz")
    assert "bar baz" == YAR.get(c, "foo")
    assert "bar baz" == YAR.get(c, "foo")
  end

  test "handle messages with line breaks", %{connection: c} do
    assert "OK" == YAR.set(c, "foo", "bar\r\nbaz")
    assert "bar\r\nbaz" == YAR.get(c, "foo")
    assert "bar\r\nbaz" == YAR.get(c, "foo")
  end

  test "huge payload", %{connection: c} do
    value = String.duplicate("asdf", 100000)
    assert "OK" == YAR.set(c, "foo", value)
    got = YAR.get(c, "foo")
    assert String.length(value) == String.length(got)
    assert value == got
  end

  test "huge pipeline", %{connection: c} do
    value = "999999888888777777666666"
    assert "OK" = YAR.set(c, "foo", value)
    commands = (1..10000) |> Enum.map(fn(_) -> ["GET", "foo"] end)
    expected = (1..10000) |> Enum.map(fn(_) -> value end)
    got = YAR.pipeline(c, commands)
    assert length(commands) == 10000
    assert length(expected) == length(got)
    assert expected == got
  end
end
