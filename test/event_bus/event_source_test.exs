defmodule EventBus.EventSourceTest do
  use ExUnit.Case
  use EventBus.EventSource

  doctest EventSource

  setup do
    EventBus.register_topic(:user_created)
    :ok
  end

  test "build with all params" do
    id = 1
    topic = :user_created
    data = %{id: 1, name: "me", email: "me@example.com"}
    transaction_id = "t1"
    ttl = 100

    params = %{
      id: id,
      topic: topic,
      transaction_id: transaction_id,
      ttl: ttl,
      source: "me"
    }

    event =
      EventSource.build params do
        Process.sleep(1_000)
        data
      end

    assert event.data == data
    assert event.id == id
    assert event.topic == topic
    assert event.transaction_id == transaction_id
    assert event.ttl == ttl
    assert event.source == "me"
    refute is_nil(event.initialized_at)
    refute is_nil(event.occurred_at)
    assert Event.duration(event) > 0
  end

  test "build without passing source" do
    topic = :user_created

    event =
      EventSource.build %{topic: topic} do
        "some event data"
      end

    assert event.source == "EventBus.EventSourceTest"
  end

  test "build without passing ttl, sets the ttl from app configuration" do
    topic = :user_created

    event =
      EventSource.build %{topic: topic} do
        "some event data"
      end

    assert event.ttl == 30_000_000
  end

  test "build without passing id, sets the id with unique_id function" do
    topic = :user_created

    event =
      EventSource.build %{topic: topic} do
        "some event data"
      end

    refute is_nil(event.id)
  end

  test "handle_yield_result/2 with error tuple and error_topic" do
    params = %{error_topic: :user_create_erred, topic: :user_created}
    result = {:error, "Username is not available"}
    expected = {:user_create_erred, result}
    assert EventSource.handle_yield_result(result, params) == expected
  end

  test "handle_yield_result/2 with error tuple without error_topic" do
    params = %{topic: :user_created}
    result = {:error, "Username is not available"}
    expected = {:user_created, result}
    assert EventSource.handle_yield_result(result, params) == expected
  end

  test "handle_yield_result/2 for any" do
    params = %{topic: :user_created}
    result = {:ok, "This is a valid result"}
    expected = {:user_created, result}
    assert EventSource.handle_yield_result(result, params) == expected
  end

  test "notify" do
    id = 1
    topic = :user_created
    data = %{id: 1, name: "me", email: "me@example.com"}

    result =
      EventSource.notify %{id: id, topic: topic} do
        data
      end

    assert result == data
  end
end
