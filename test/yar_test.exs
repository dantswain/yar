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
    assert {:error, "unknown command 'WTFISNOTACOMMAND'"} ==
      YAR.execute(c, "WTFISNOTACOMMAND")
  end

  test "mget array response", %{connection: c} do
    assert "OK" == YAR.execute(c, "SET FOO BANG")
    assert "OK" == YAR.execute(c, "SET BAR BLAM")
    assert ["BANG", "BLAM"] == YAR.execute(c, "MGET FOO BAR")
  end

  test "pass in iolist", %{connection: c} do
    assert "OK" == YAR.execute(c, ["SET", "FOO BAR"])
    assert "BAR" == YAR.execute(c, ['GET', 'FOO'])
  end

  test "does not handle mixed iolists", %{connection: c}  do
    assert {:error, "Protocol error: expected '$', got ' '"} ==
      YAR.execute(c, ["SET", 'FOO', "1"])
  end
end
