defmodule EventBus.WatcherTest do
  use ExUnit.Case, async: false
  alias EventBus.Watcher

  alias EventBus.Support.Helper.{
    InputLogger,
    Calculator,
    MemoryLeakerOne,
    BadOne
  }

  doctest EventBus.Watcher

  setup do
    :ok
  end

  test "register_topic" do
    assert :ok == Watcher.register_topic(:metrics_destroyed)
  end

  test "unregister_topic" do
    topic = :metrics_destroyed
    Watcher.register_topic(topic)

    assert :ok == Watcher.unregister_topic(topic)
  end

  test "create" do
    topic = :some_event_occurred1
    id = "E1"

    listeners = [
      {InputLogger, %{}},
      {Calculator, %{}},
      {MemoryLeakerOne, %{}},
      {BadOne, %{}}
    ]

    Watcher.register_topic(topic)

    assert :ok == Watcher.create({listeners, topic, id})
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
    Watcher.create({listeners, topic, id})

    assert :ok === Watcher.mark_as_completed({{InputLogger, %{}}, topic, id})
  end

  test "skip" do
    topic = :some_event_occurred3
    id = "E1"

    listeners = [
      {InputLogger, %{}},
      {Calculator, %{}},
      {MemoryLeakerOne, %{}},
      {BadOne, %{}}
    ]

    Watcher.register_topic(topic)
    Watcher.create({listeners, topic, id})
    assert :ok == Watcher.mark_as_skipped({{InputLogger, %{}}, topic, id})
  end
end
