defmodule EventBus.Manager.StoreTest do
  use ExUnit.Case, async: false
  alias EventBus.Model.Event
  alias EventBus.Manager.Store

  doctest Store

  @topic :metrics_stored

  setup do
    refute is_nil(Process.whereis(Store))

    Store.unregister_topic(@topic)
    Store.register_topic(@topic)
    :ok
  end

  test "exist?" do
    topic = :metrics_received_1
    Store.register_topic(topic)

    assert Store.exist?(topic)
  end

  test "register_topic" do
    assert :ok == Store.register_topic(@topic)
  end

  test "unregister_topic" do
    Store.register_topic(@topic)
    assert :ok == Store.unregister_topic(@topic)
  end

  test "create" do
    event = %Event{id: "E1", transaction_id: "T1", data: %{}, topic: @topic}
    assert :ok == Store.create(event)
  end

  test "delete" do
    event = %Event{id: "E1", transaction_id: "T1", data: [1, 2], topic: @topic}
    Store.create(event)

    assert :ok == Store.delete({event.topic, event.id})
  end
end
