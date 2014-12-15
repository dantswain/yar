YAR
===

Yet Another Redis client for Elixir

YAR is a [Redis](http://redis.io) client written in Elixir.  It is
not a wrapper around the excellent Erlang client
[eredis](https://github.com/wooga/eredis), it is implemented
from scratch in Elixir using
[elixir-socket](https://github.com/meh/elixir-socket)
(which is itself a wrapper around Erlang's `gen_tcp`)
for TCP/IP communication.

I started this project mainly as a learning exercise.  It is NOT
ready for production :)  The defacto Elixir Redis client appears
to be [exredis](https://github.com/artemeff/exredis).

##Usage

Create a new Redis connection process with `YAR.connect/2` and then
use `YAR.execute/2` to execute raw Redis commands.

```elixir
{:ok, redis} = YAR.connect("localhost", 6379)
"PONG" = YAR.execute(redis, "PING")
"OK" = YAR.execute(redis, "SET FOO 1")
2 = YAR.execute(redis, "INCR FOO")
"2" = YAR.execute(redis, "GET FOO")
"OK" = YAR.execute(redis, "SET BAR BAZ")
["2", "BAZ"] = YAR.execute(redis, "MGET FOO BAR")
{:error, "unknown command 'SUP'"} = YAR.execute(redis, "SUP")
```

`YAR.connect/2` takes host and port as arguments, with
default values of "localhost" and 6379. `{:ok, redis} = Yar.connect` 
should connect to a default local instance of redis-server on most
installations.  Multiple connections can be made by simply
calling `Yar.connect/2` multiple times.

In theory, YAR supports arbitrary Redis commands via
`YAR.execute/2`.  All of the basic return types should be
supported.

`YAR.execute/2` is synchronous.  The underlying connection uses
[elixir-socket](https://github.com/meh/elixir-socket) and stores
the connection information in a GenServer.

##Testing

Launch a Redis server instance on port 5000 (`redis-server -- port 5000`)
then run `mix test`.

*CAUTION* - The test executes `FLUSHALL` between test cases. DO NOT
test on a production server!  If you must, take care that no
data is kept on a Redis instance on port 5000, or change the test port
in `test/yar_test.exs`.
