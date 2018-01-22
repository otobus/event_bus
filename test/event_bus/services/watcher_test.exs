defmodule EventBus.Service.WatcherTest do
  use ExUnit.Case, async: false
  alias EventBus.Service.Watcher

  alias EventBus.Support.Helper.{
    InputLogger,
    Calculator,
    MemoryLeakerOne,
    BadOne
  }

  doctest Watcher

  setup do
    :ok
  end

  test "register_topic" do
    topic = :metrics_destroyed
    Watcher.register_topic(topic)
    Process.sleep(1_000)
    all_tables = :ets.all()

    assert Enum.any?(all_tables, fn t -> t == :"eb_ew_#{topic}" end)
  end

  test "unregister_topic" do
    topic = :metrics_destroyed
    Watcher.register_topic(topic)
    Watcher.unregister_topic(topic)
    Process.sleep(1_000)
    all_tables = :ets.all()

    refute Enum.any?(all_tables, fn t -> t == :"eb_ew_#{topic}" end)
  end

  test "create and fetch" do
    topic = :some_event_occurred1
    id = "E1"

    listeners = [
      {InputLogger, %{}},
      {Calculator, %{}},
      {MemoryLeakerOne, %{}},
      {BadOne, %{}}
    ]

    Watcher.register_topic(topic)
    Process.sleep(100)
    Watcher.save({topic, id}, {listeners, [], []})
    Process.sleep(100)

    assert {listeners, [], []} == Watcher.fetch({topic, id})
  end

  test "complete" do
    topic = :some_event_occurred2
    id = "E1"

    listeners = [
      {InputLogger, %{}},
      {Calculator, %{}},
      {MemoryLeakerOne, %{}},
      {BadOne, %{}}
    ]

    Watcher.register_topic(topic)
    Process.sleep(100)
    Watcher.save({topic, id}, {listeners, [], []})
    Process.sleep(100)
    Watcher.mark_as_completed({{InputLogger, %{}}, topic, id})
    Process.sleep(100)

    assert {listeners, [{InputLogger, %{}}], []} == Watcher.fetch({topic, id})
  end

  test "skip" do
    id = "E1"
    topic = :some_event_occurred3

    listeners = [
      {InputLogger, %{}},
      {Calculator, %{}},
      {MemoryLeakerOne, %{}},
      {BadOne, %{}}
    ]

    Watcher.register_topic(topic)
    Process.sleep(100)
    Watcher.save({topic, id}, {listeners, [], []})
    Process.sleep(100)
    Watcher.mark_as_skipped({{InputLogger, %{}}, topic, id})
    Process.sleep(100)

    assert {listeners, [], [{InputLogger, %{}}]} == Watcher.fetch({topic, id})
  end
end
