# EventBus

[![Build Status](https://travis-ci.org/mustafaturan/event_bus.svg?branch=master)](https://travis-ci.org/mustafaturan/event_bus)

Simple event bus implementation.

## Installation

The package can be installed by adding `event_bus` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:event_bus, "~> 0.1.0"}]
end
```

## Usage

Module docs can be found at [https://hexdocs.pm/event_bus](https://hexdocs.pm/event_bus).

Subscribe to the 'event bus'
```elixir
EventBus.subscribe(MyEventListener)
```

Unsubscribe from the 'event bus'
```elixir
EventBus.unsubscribe(MyEventListener)
```

List subscribers
```elixir
EventBus.subscribers()
```

Notify all subscribers with any type of data
```elixir
EventBus.notify(:hello_received, %{message: "Hello"})
EventBus.notify(:bye_received, [user_id: 1, goal: "exit"])
```

### Sample Listener Implementation

```elixir
defmodule MyEventListener do
  ...

  def process({:hello_received, _event_data} = event) do
    GenServer.cast(__MODULE__, event)
  end
  def process({:bye_received, event_data}) do
    # do sth
    :ok
  end
  def process({event_type, event_data}) do
    # this one matches all events
    :ok
  end

  ...
end
```

## Todo

- [ ] Move event data to ETS and pass key instead of data to listeners

## Contributing

### Issues, Bugs, Documentation, Enhancements

1. Fork the project

2. Make your improvements and write your tests(make sure you covered all the cases).

3. Make a pull request.

## License

MIT
