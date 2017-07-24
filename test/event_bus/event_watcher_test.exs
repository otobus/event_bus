defmodule EventBus.EventWatcherTest do
  use ExUnit.Case
  alias EventBus.EventWatcher
  alias EventBus.Support.Helper.{InputLogger, Calculator, MemoryLeakerOne,
    BadOne}
  doctest EventBus.EventWatcher

  setup do
    :ok
  end

  test "register_event" do
    name = :metrics_destroyed
    EventWatcher.register_event(name)
    Process.sleep(1_000)
    all_tables = :ets.all()

    assert Enum.any?(all_tables, fn t -> t == :"eb_ew_#{name}" end)
  end

  test "create and fetch" do
    name = :some_event_occurred1
    EventWatcher.register_event(name)
    Process.sleep(100)

    processors = [InputLogger, Calculator, MemoryLeakerOne, BadOne]
    type = :some_event_occurred1
    key = UUID.uuid1()

    EventWatcher.create({processors, type, key})
    Process.sleep(100)

    assert {processors, [], []} == EventWatcher.fetch({type, key})
  end

  test "complete" do
    name = :some_event_occurred2
    EventWatcher.register_event(name)
    Process.sleep(100)

    processors = [InputLogger, Calculator, MemoryLeakerOne, BadOne]
    type = :some_event_occurred2
    key = UUID.uuid1()

    EventWatcher.create({processors, type, key})
    Process.sleep(100)
    EventWatcher.mark_as_completed({InputLogger, type, key})
    Process.sleep(100)

    assert {processors, [InputLogger], []} == EventWatcher.fetch({type, key})
  end

  test "skip" do
    name = :some_event_occurred3
    EventWatcher.register_event(name)
    Process.sleep(100)

    processors = [InputLogger, Calculator, MemoryLeakerOne, BadOne]
    type = :some_event_occurred3
    key = UUID.uuid1()

    EventWatcher.create({processors, type, key})
    Process.sleep(100)
    EventWatcher.mark_as_skipped({InputLogger, type, key})
    Process.sleep(100)

    assert {processors, [], [InputLogger]} == EventWatcher.fetch({type, key})
  end
end
