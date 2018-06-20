defmodule EventBus.Service.StoreTest do
  use ExUnit.Case, async: false
  alias EventBus.Model.Event
  alias EventBus.Service.Store

  doctest Store

  setup do
    :ok
  end

  test "exist?" do
    topic = :metrics_received_1
    Store.register_topic(topic)

    assert Store.exist?(topic)
  end

  test "register_topic" do
    topic = :metrics_received_1
    Store.register_topic(topic)
    all_tables = :ets.all()

    assert Enum.any?(all_tables, fn t -> t == :"eb_es_#{topic}" end)
  end

  test "unregister_topic" do
    topic = :metrics_received_1
    Store.unregister_topic(topic)
    all_tables = :ets.all()

    refute Enum.any?(all_tables, fn t -> t == :"eb_es_#{topic}" end)
  end

  test "create" do
    topic = :metrics_received_2
    Store.register_topic(topic)

    event = %Event{
      id: "E1",
      transaction_id: "T1",
      data: ["Mustafa", "Turan"],
      topic: topic
    }

    assert :ok == Store.create(event)
  end

  test "fetch" do
    topic = :metrics_received_3
    Store.register_topic(topic)

    first_event = %Event{
      id: "E1",
      transaction_id: "T1",
      data: ["Mustafa", "Turan"],
      topic: topic
    }

    second_event = %Event{
      id: "E2",
      transaction_id: "T1",
      data: %{name: "Mustafa", surname: "Turan"},
      topic: topic
    }

    :ok = Store.create(first_event)
    :ok = Store.create(second_event)

    assert first_event == Store.fetch({topic, first_event.id})
    assert second_event == Store.fetch({topic, second_event.id})
  end

  test "fetch_data" do
    topic = :metrics_received_4
    Store.register_topic(topic)

    event = %Event{
      id: "E1",
      transaction_id: "T1",
      data: ["Mustafa", "Turan"],
      topic: topic
    }

    :ok = Store.create(event)

    assert event.data == Store.fetch_data({topic, event.id})
  end

  test "delete and fetch" do
    topic = :metrics_received_5
    Store.register_topic(topic)

    event = %Event{
      id: "E1",
      transaction_id: "T1",
      data: ["Mustafa", "Turan"],
      topic: topic
    }

    :ok = Store.create(event)
    Store.delete({topic, event.id})

    assert is_nil(Store.fetch({topic, event.id}))
  end
end
