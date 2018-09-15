defmodule EventBus.Model.EventTest do
  use ExUnit.Case
  require EventBus.Model.Event
  alias EventBus.Model.Event
  alias EventBus.Util.MonotonicTime

  doctest Event

  setup do
    EventBus.register_topic(:user_created)
    :ok
  end

  test "duration" do
    initialized_at = MonotonicTime.now()
    # Do sth in this frame
    # For example; sleep 1 second
    Process.sleep(1_000)

    event = %Event{
      id: 1,
      topic: "user_created",
      data: %{id: 1, name: "me", email: "me@example.com"},
      initialized_at: initialized_at,
      occurred_at: MonotonicTime.now()
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
end
