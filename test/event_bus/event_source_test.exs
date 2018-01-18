defmodule EventBus.EventSourceTest do
  use ExUnit.Case
  use EventBus.EventSource

  doctest EventSource

  setup do
    EventBus.register_topic(:user_created)
    :ok
  end

  test "build with source" do
    id = 1
    topic = :user_created
    data = %{id: 1, name: "me", email: "me@example.com"}
    transaction_id = "t1"
    ttl = 100

    event =
      EventSource.build %{
        id: id,
        topic: topic,
        transaction_id: transaction_id,
        ttl: ttl,
        source: "me"
      } do
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
  end

  test "build without source" do
    id = 1
    topic = :user_created
    data = %{id: 1, name: "me", email: "me@example.com"}
    transaction_id = "t1"
    ttl = 100

    event =
      EventSource.build %{
        id: id,
        topic: topic,
        transaction_id: transaction_id,
        ttl: ttl
      } do
        data
      end

    assert event.data == data
    assert event.id == id
    assert event.topic == topic
    assert event.transaction_id == transaction_id
    assert event.ttl == ttl
    assert event.source == "EventBus.EventSourceTest"
    refute is_nil(event.initialized_at)
    refute is_nil(event.occurred_at)
  end

  test "build with error topic" do
    id = 1
    topic = :user_created
    error_topic = :user_create_erred
    data = %{email: "Invalid format"}
    transaction_id = "t1"
    ttl = 100

    event =
      EventSource.build %{
        id: id,
        topic: topic,
        transaction_id: transaction_id,
        ttl: ttl,
        error_topic: error_topic
      } do
        {:error, data}
      end

    assert event.data == {:error, data}
    assert event.id == id
    assert event.topic == error_topic
    assert event.transaction_id == transaction_id
    assert event.ttl == ttl
    assert event.source == "EventBus.EventSourceTest"
    refute is_nil(event.initialized_at)
    refute is_nil(event.occurred_at)
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
