defmodule EventBus.EventStoreTest do
  use ExUnit.Case, async: false
  alias EventBus.Model.Event
  alias EventBus.EventStore

  doctest EventBus.EventStore

  setup do
    :ok
  end

  test "register_topic" do
    topic = :metrics_received_1
    EventStore.register_topic(topic)
    Process.sleep(100)
    all_tables = :ets.all()

    assert Enum.any?(all_tables, fn t -> t == :"eb_es_#{topic}" end)
  end

  test "unregister_topic" do
    topic = :metrics_received_1
    EventStore.unregister_topic(topic)
    Process.sleep(100)
    all_tables = :ets.all()

    refute Enum.any?(all_tables, fn t -> t == :"eb_es_#{topic}" end)
  end

  test "save" do
    topic = :metrics_received_2
    EventStore.register_topic(topic)
    Process.sleep(100)

    event = %Event{id: "E1", transaction_id: "T1", data: ["Mustafa", "Turan"],
      topic: topic}

    assert :ok == EventStore.save(event)
  end

  test "fetch" do
    topic = :metrics_received_3
    EventStore.register_topic(topic)
    Process.sleep(100)

    first_event = %Event{id: "E1", transaction_id: "T1",
      data: ["Mustafa", "Turan"], topic: topic}
    second_event = %Event{id: "E2", transaction_id: "T1",
      data: %{name: "Mustafa", surname: "Turan"}, topic: topic}

    :ok = EventStore.save(first_event)
    :ok = EventStore.save(second_event)

    assert first_event == EventStore.fetch({topic, first_event.id})
    assert second_event == EventStore.fetch({topic, second_event.id})
  end

  test "delete and fetch" do
    topic = :metrics_received_4
    EventStore.register_topic(topic)
    Process.sleep(100)

    event = %Event{id: "E1", transaction_id: "T1", data: ["Mustafa", "Turan"],
      topic: topic}

    :ok = EventStore.save(event)
    EventStore.delete({topic, event.id})
    Process.sleep(100)

    assert is_nil(EventStore.fetch({topic, event.id}))
  end
end
