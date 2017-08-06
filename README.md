# EventBus

[![Build Status](https://travis-ci.org/mustafaturan/event_bus.svg?branch=master)](https://travis-ci.org/mustafaturan/event_bus)

Simple event bus implementation using ETS as an event store.

![Event Bus](https://cdn-images-1.medium.com/max/1600/1*0fcfAiHvNeHCRYhp-a32YA.png)

## Installation

The package can be installed by adding `event_bus` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:event_bus, "~> 0.4.0"}]
end
```

## Usage

Register events in `config.exs`
In your config.exs you can register events
```elixir
config :event_bus, events: [:message_received, :another_event_occured]
```

Subscribe to the 'event bus' with a listener and list of given topics, EventManager will match with Regex

```elixir
# to catch every event topic
EventBus.subscribe({MyEventListener, [".*"]})
> :ok

# to catch specific topics
EventBus.subscribe({MyEventListener, ["purchase_", "booking_confirmed$", "flight_passed$"]})
> :ok
```

Unsubscribe from the 'event bus'
```elixir
EventBus.unsubscribe(MyEventListener)
> :ok
```

List subscribers
```elixir
EventBus.subscribers()
> [{MyEventListener, [".*"]}]
```

List subscribers of a specific event
```elixir
EventBus.subscribers(:hello_received)
> [MyEventListener]
```

Notify all subscribers with any type of data
```elixir
EventBus.notify({:hello_received, %{message: "Hello"}})
> :ok
EventBus.notify({:bye_received, [user_id: 1, goal: "exit"]})
> :ok
```

Fetch event data
```elixir
EventBus.fetch_event_data({:bye_received, event_key})
> [user_id: 1, goal: "exit"]
```

Mark as completed on Event Watcher
```elixir
EventBus.mark_as_completed({MyEventListener, :bye_received, event_key})
> :ok
```

Mark as skipped on Event Watcher
```elixir
EventBus.mark_as_skipped({MyEventListener, :bye_received, event_key})
> :ok
```

### Sample Listener Implementation

```elixir
defmodule MyEventListener do
  ...

  def process({topic, key} = event_shadow) do
    GenServer.cast(__MODULE__, event_shadow)
    :ok
  end

  ...


  def handle_cast({:bye_received, event_key}, state) do
    event_data = EventBus.fetch_event_data({:bye_received, event_key})
    # do sth with event_data

    # update the watcher!
    EventBus.mark_as_completed({__MODULE__, :bye_received, event_key})
    ...
    {:noreply, state}
  end
  def handle_cast({:hello_received, event_key}, state) do
    event_data = EventBus.fetch_event_data({:hello_received, event_key})
    # do sth with event_data

    # update the watcher!
    EventBus.mark_as_completed({__MODULE__, :hello_received, event_key})
    ...
    {:noreply, state}
  end
  def handle_cast({topic, key}, state) do
    EventBus.mark_as_skipped({__MODULE__, topic, key})
    {:noreply, state}
  end

  ...
end
```

### Event Storage Details

When an event configured in `config` file, 2 ETS tables will be created for the event on app start.

All event data is temporarily saved to the ETS tables with the name `:eb_es_<<event_name>>` until all subscribers processed the data. This table is a read heavy table, when a subscriber need to process the event data, it queries this table to fetch event data.

And a watcher table is created for the events with the name `:eb_ew_<<event_name>>` and these tables are used for keeping the trace of the status of events. EventWatcher is an active-writer actor for these table. When all subscribers process the event data, event data and watcher data automatically deleted by the EventWatcher. Usually, there is no read on this table but if you need to see status of events, it is one of the good places to query.

For example; to get the list unprocessed events for `:hello_received` event:

```elixir
# The following command will return a list of tuples with the `event_key`, and `event_subscribers_list` where `subscribers` is the list of event subscribers, `completers` is the subscribers those processed the event and notified EventWatcher, and lastly `skippers` is the subscribers those skipped the event without processing.

# Assume you have an event with the name ':hello_received'
:ets.tab2list(:eb_ew_hello_received)
> [{event_key, {subscribers, completers, skippers}}, ...]
```

ETS storage SHOULD NOT be considered as a persistent storage. If you need to store events to a persistant data store, then subscribe to all event types by a module with `[".*"]` event topic then save every event data.

For example;

```elixir
EventBus.subscribe({MyDataStore, [".*"]})

# then in your data store save the event
defmodule MyDataStore do
  ...

  def process({topic, key} = event_shadow) do
    GenServer.cast(__MODULE__, event_shadow)
    :ok
  end

  ...

  def handle_cast({topic, key}, state) do
    event_data = EventBus.fetch_event_data({topic, key})
    # write your logic to save event_data to a persistant store

    EventBus.mark_as_comleted({__MODULE__, topic, key})
    {:noreply, state}
  end
end
```

### Documentation

Module docs can be found at [https://hexdocs.pm/event_bus](https://hexdocs.pm/event_bus).

Implementation detail can be found at: https://medium.com/@mustafaturan/event-bus-implementation-s-d2854a9fafd5

## Contributing

### Issues, Bugs, Documentation, Enhancements

1. Fork the project

2. Make your improvements and write your tests(make sure you covered all the cases).

3. Make a pull request.

## License

MIT
