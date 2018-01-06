defmodule EventBus.Model.EventTest do
  use ExUnit.Case
  alias EventBus.Model.Event

  doctest Event

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
end
