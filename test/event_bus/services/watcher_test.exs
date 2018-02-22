defmodule EventBus.Service.WatcherTest do
  use ExUnit.Case, async: false
  alias EventBus.Service.{Watcher, Topic}
  alias EventBus.Support.Helper.{
    InputLogger,
    Calculator,
    MemoryLeakerOne,
    BadOne
  }

  doctest Watcher

  @sys_topic :eb_action_called

  setup do
    on_exit(fn ->
      topics = Topic.all() -- [@sys_topic, :metrics_received, :metrics_summed]
      Enum.each(topics, fn topic -> Topic.unregister(topic) end)
    end)

    :ok
  end

  test "exist?" do
    topic = :metrics_received_1
    Watcher.register_topic(topic)

    assert Watcher.exist?(topic)
  end

  test "register_topic" do
    topic = :metrics_destroyed
    Watcher.register_topic(topic)
    all_tables = :ets.all()

    assert Enum.any?(all_tables, fn t -> t == :"eb_ew_#{topic}" end)
  end

  test "unregister_topic" do
    topic = :metrics_destroyed
    Watcher.register_topic(topic)
    Watcher.unregister_topic(topic)
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
    Watcher.save({topic, id}, {listeners, [], []})

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
    Watcher.save({topic, id}, {listeners, [], []})
    Watcher.mark_as_completed({{InputLogger, %{}}, topic, id})

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
    Watcher.save({topic, id}, {listeners, [], []})
    Watcher.mark_as_skipped({{InputLogger, %{}}, topic, id})

    assert {listeners, [], [{InputLogger, %{}}]} == Watcher.fetch({topic, id})
  end
end
