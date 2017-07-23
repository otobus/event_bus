defmodule EventBus.EventStoreTest do
  use ExUnit.Case
  alias EventBus.EventStore
  doctest EventBus.EventStore

  setup do
    :ok
  end

  test "register_event" do
    name = :metrics_destroyed1
    EventStore.register_event(name)
    Process.sleep(100)
    all_tables = :ets.all()

    assert Enum.any?(all_tables, fn t -> t == :"eb_es_#{name}" end)
  end

  test "save" do
    type = :metrics_destroyed2
    EventStore.register_event(type)
    Process.sleep(100)

    key = UUID.uuid1()
    data = ["Mustafa", "Turan"]

    assert :ok == EventStore.save({type, key, data})
  end

  test "fetch" do
    type = :metrics_destroyed3
    EventStore.register_event(type)
    Process.sleep(100)

    key1 = UUID.uuid1()
    data1 = ["Mustafa", "Turan"]
    key2 = UUID.uuid1()
    data2 = %{name: "Mustafa", surname: "Turan"}

    :ok = EventStore.save({type, key1, data1})
    :ok = EventStore.save({type, key2, data2})

    assert data1 == EventStore.fetch({type, key1})
    assert data2 == EventStore.fetch({type, key2})
  end

  test "delete and fetch" do
    type = :metrics_destroyed4
    EventStore.register_event(type)
    Process.sleep(100)

    key1 = UUID.uuid1()
    data1 = ["Mustafa", "Turan"]
    key2 = UUID.uuid1()
    data2 = %{name: "Mustafa", surname: "Turan"}

    :ok = EventStore.save({type, key1, data1})
    :ok = EventStore.save({type, key2, data2})
    EventStore.delete({type, key1})
    Process.sleep(100)
    assert is_nil(EventStore.fetch({type, key1}))

  end
end
