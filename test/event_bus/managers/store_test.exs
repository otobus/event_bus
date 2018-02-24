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

  test "register_topic" do
    assert :ok == Store.register_topic(@topic)
  end

  test "unregister_topic" do
    Store.register_topic(@topic)
    assert :ok == Store.unregister_topic(@topic)
  end

  test "save" do
    event = %Event{id: "E1", transaction_id: "T1", data: %{}, topic: @topic}
    assert :ok == Store.save(event)
  end

  test "delete" do
    event = %Event{id: "E1", transaction_id: "T1", data: [1, 2], topic: @topic}
    Store.save(event)

    assert :ok == Store.delete({event.topic, event.id})
  end
end
