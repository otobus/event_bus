defmodule EventBus.Service.StoreTest do
  use ExUnit.Case, async: false
  alias EventBus.Model.Event
  alias EventBus.Service.Store

  doctest Store

  setup do
    :ok
  end

  test "register_topic" do
    topic = :metrics_received_1
    Store.register_topic(topic)
    Process.sleep(100)
    all_tables = :ets.all()

    assert Enum.any?(all_tables, fn t -> t == :"eb_es_#{topic}" end)
  end

  test "unregister_topic" do
    topic = :metrics_received_1
    Store.unregister_topic(topic)
    Process.sleep(100)
    all_tables = :ets.all()

    refute Enum.any?(all_tables, fn t -> t == :"eb_es_#{topic}" end)
  end

  test "save" do
    topic = :metrics_received_2
    Store.register_topic(topic)
    Process.sleep(100)

    event = %Event{
      id: "E1",
      transaction_id: "T1",
      data: ["Mustafa", "Turan"],
      topic: topic
    }

    assert :ok == Store.save(event)
  end

  test "fetch" do
    topic = :metrics_received_3
    Store.register_topic(topic)
    Process.sleep(100)

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

    :ok = Store.save(first_event)
    :ok = Store.save(second_event)

    assert first_event == Store.fetch({topic, first_event.id})
    assert second_event == Store.fetch({topic, second_event.id})
  end

  test "delete and fetch" do
    topic = :metrics_received_4
    Store.register_topic(topic)
    Process.sleep(100)

    event = %Event{
      id: "E1",
      transaction_id: "T1",
      data: ["Mustafa", "Turan"],
      topic: topic
    }

    :ok = Store.save(event)
    Store.delete({topic, event.id})
    Process.sleep(100)

    assert is_nil(Store.fetch({topic, event.id}))
  end
end
