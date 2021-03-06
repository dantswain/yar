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

This project is probably not ready for production, though I would
greatly appreciate any feedback and bug reports.

If you are looking for a solid Elixir Redis client,
check out [exredis](https://github.com/artemeff/exredis).
exredis is a wrapper around [eredis](https://github.com/wooga/eredis),
which is an Erlang Redis client that has been around for quite
some time.

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
"OK" = YAR.execute(redis, ["SET", "BAR", "BAZ"])
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

The list form of execute should be favored for performance reasons.
That is, `YAR.execute(redis, ["GET", "FOO"])` is slightly more
performant than `YAR.execute(redis, "GET FOO")`.

##Helpers

YAR has built-in helpers for some Redis commands.

```elixir
"OK" == YAR.set(c, "foo", "bar")
"bar" == YAR.get(c, "foo")
# note keys/values are interleaved
"OK" == YAR.mset(c, ["foo", 1, "bar", 2])
["1", "2"] == YAR.mget(c, ["foo"], ["bar"])
```

##Pipelining

YAR supports simple [Redis pipelining](http://redis.io/topics/pipelining)
via `YAR.pipeline/2`.  The second argument
is a list of commands.  The responses are returned as a list in order
corresponding to the commands.

```elixir
["OK", "PING"] == YAR.pipeline(redis, [["SET", "FOO", "42"], ["PING"]])
["42", "OK"] == YAR.pipeline(redis, [["GET", "FOO"], ["SET", "FOO", "1"]])
```

##Pubsub

YAR supports simple [Redis subscribing](http://redis.io/topics/pubsub)
via `YAR.subscribe/4`.  The first argument is a pid to receive
messages, the second argument is a list of routing keys, the
third and fourth arguments are the Redis host and port, respectively
(default "localhost" and 5379).  Messages are delivered as tuples
where the first element is `:yarsub` and the second argument is
the message string.

```elixir
{:ok, subscriber_pid} = YAR.subscribe(self, ["foo"])
YAR.execute(redis, ["PUBLISH", "foo", "hullo"])
flush # => {:yarsub, "hullo"}
```

##Testing

Launch a Redis server instance on port 5000 (`redis-server -- port 5000`)
then run `mix test`.

*CAUTION* - The test executes `FLUSHALL` between test cases. DO NOT
test on a production server!  If you must, take care that no
data is kept on a Redis instance on port 5000, or change the test port
in `test/yar_test.exs`.
