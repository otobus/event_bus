defmodule EventBus.EventWatcherTest do
  use ExUnit.Case, async: false
  alias EventBus.EventWatcher
  alias EventBus.Support.Helper.{InputLogger, Calculator, MemoryLeakerOne,
    BadOne}
  doctest EventBus.EventWatcher

  setup do
    :ok
  end

  test "register_topic" do
    topic = :metrics_destroyed
    EventWatcher.register_topic(topic)
    Process.sleep(1_000)
    all_tables = :ets.all()

    assert Enum.any?(all_tables, fn t -> t == :"eb_ew_#{topic}" end)
  end

  test "unregister_topic" do
    topic = :metrics_destroyed
    EventWatcher.register_topic(topic)
    EventWatcher.unregister_topic(topic)
    Process.sleep(1_000)
    all_tables = :ets.all()

    refute Enum.any?(all_tables, fn t -> t == :"eb_ew_#{topic}" end)
  end

  test "create and fetch" do
    topic = :some_event_occurred1
    EventWatcher.register_topic(topic)
    Process.sleep(100)

    processors = [InputLogger, Calculator, MemoryLeakerOne, BadOne]
    id = "E1"

    EventWatcher.create({processors, topic, id})
    Process.sleep(100)

    assert {processors, [], []} == EventWatcher.fetch({topic, id})
  end

  test "complete" do
    topic = :some_event_occurred2
    EventWatcher.register_topic(topic)
    Process.sleep(100)

    processors = [InputLogger, Calculator, MemoryLeakerOne, BadOne]
    id = "E1"

    EventWatcher.create({processors, topic, id})
    Process.sleep(100)
    EventWatcher.mark_as_completed({InputLogger, topic, id})
    Process.sleep(100)

    assert {processors, [InputLogger], []} == EventWatcher.fetch({topic, id})
  end

  test "skip" do
    topic = :some_event_occurred3
    EventWatcher.register_topic(topic)
    Process.sleep(100)

    processors = [InputLogger, Calculator, MemoryLeakerOne, BadOne]
    id = "E1"

    EventWatcher.create({processors, topic, id})
    Process.sleep(100)
    EventWatcher.mark_as_skipped({InputLogger, topic, id})
    Process.sleep(100)

    assert {processors, [], [InputLogger]} == EventWatcher.fetch({topic, id})
  end
end
