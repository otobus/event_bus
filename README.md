# EventBus

[![Build Status](https://travis-ci.org/mustafaturan/event_bus.svg?branch=master)](https://travis-ci.org/mustafaturan/event_bus)

Simple event bus implementation using ETS as an event store.

## Installation

The package can be installed by adding `event_bus` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:event_bus, "~> 0.2.1"}]
end
```

## Usage

Register events in `config.exs` (recommended way)
In your config.exs you can register events
```elixir
config :event_bus, events: [:message_received, :another_event_occured]
```

Register events on demand
```elixir
EventBus.register_event(:my_test_event_occured)
```

Subscribe to the 'event bus' with listener and list of given topics, EventManager will match with Regex
```elixir
# to catch every event topic
EventBus.subscribe({MyEventListener, [".*"]})

# to catch specific topics
EventBus.subscribe({MyEventListener, ["purchase_", booking_confirmed$", "fligt_passed$"]})
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

Fetch event data
```elixir
EventBus.fetch_event_data({:bye_received, event_key})
```

Mark as completed on Event Watcher
```elixir
EventBus.complete({MyEventListener, :bye_received, event_key})
```

Mark as skipped on Event Watcher
```elixir
EventBus.skip({MyEventListener, :bye_received, event_key})
```

### Sample Listener Implementation

```elixir
defmodule MyEventListener do
  ...

  def process({event_type, event_key}) do
    GenServer.cast(__MODULE__, event_shadow)
    :ok
  end

  ...


  def handle_cast({:bye_received, event_key}, state) do
    event_data = EventBus.fetch_event_data({:hello_received, event_key})
    # do sth with event_data

    # update the watcher!
    EventWatcher.complete({__MODULE__, :hello_received, event_key})
    ...
    {:noreply, state}
  end
  def handle_cast({:hello_received, event_key}, state) do
    event_data = EventBus.fetch_event_data({:hello_received, event_key})
    # do sth with event_data

    # update the watcher!
    EventWatcher.complete({__MODULE__, :hello_received, event_key})
    ...
    {:noreply, state}
  end
  def handle_cast({_, _}, state) do
    EventBus.skip({__MODULE__, event_type, event_key})
    {:noreply, state}
  end

  ...
end
```

### Module Documentation

Module docs can be found at [https://hexdocs.pm/event_bus](https://hexdocs.pm/event_bus).

## Contributing

### Issues, Bugs, Documentation, Enhancements

1. Fork the project

2. Make your improvements and write your tests(make sure you covered all the cases).

3. Make a pull request.

## License

MIT
