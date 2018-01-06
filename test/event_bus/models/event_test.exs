defmodule EventBus.Model.EventTest do
  use ExUnit.Case
  require EventBus.Model.Event
  alias EventBus.Model.Event

  doctest Event

  setup do
    EventBus.register_topic(:user_created)
    :ok
  end

  test "duration" do
    initialized_at = :os.system_time(:nano_seconds)
    Process.sleep(1) # do sth in this frame

    event = %Event{
      id: 1,
      topic: "user_created",
      data: %{id: 1, name: "me", email: "me@example.com"},
      initialized_at: initialized_at,
      occurred_at: :os.system_time(:nano_seconds)
    }
    assert Event.duration(event) > 0
  end

  test "duration should return 0 if initialized_at and/or occurred_at is nil" do
    event = %Event{
      id: 1,
      topic: "user_created",
      data: %{id: 1, name: "me", email: "me@example.com"}
    }
    assert Event.duration(event) == 0
  end

  test "build" do
    id = 1
    topic = "user_created"
    data = %{id: 1, name: "me", email: "me@example.com"}
    transaction_id = "t1"
    ttl = 100
    event =
      Event.build(id, topic, transaction_id, ttl) do
        data
      end
    assert event.data == data
    assert event.id == id
    assert event.topic == topic
    assert event.transaction_id == transaction_id
    assert event.ttl == ttl
    refute is_nil(event.initialized_at)
    refute is_nil(event.occurred_at)
  end

  test "notify" do
    id = 1
    topic = "user_created"
    data = %{id: 1, name: "me", email: "me@example.com"}
    result =
      Event.notify(id, topic) do
        data
      end
    assert result == data
  end
end
