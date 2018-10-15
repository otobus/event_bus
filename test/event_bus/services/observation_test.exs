defmodule EventBus.Service.ObservationTest do
  use ExUnit.Case, async: false

  alias EventBus.Service.{Observation, Topic}
  alias EventBus.Support.Helper.{
    BadOne,
    Calculator,
    InputLogger,
    MemoryLeakerOne
  }

  doctest Observation

  setup do
    on_exit(fn ->
      topics = Topic.all() -- [:metrics_received, :metrics_summed]
      Enum.each(topics, fn topic -> Topic.unregister(topic) end)
    end)

    :ok
  end

  test "exist?" do
    topic = :metrics_received_1
    Observation.register_topic(topic)

    assert Observation.exist?(topic)
  end

  test "register_topic" do
    topic = :metrics_destroyed
    Observation.register_topic(topic)
    all_tables = :ets.all()
    table_name = String.to_atom("eb_ew_#{topic}")

    assert Enum.any?(all_tables, fn t -> t == table_name end)
  end

  test "unregister_topic" do
    topic = :metrics_destroyed
    Observation.register_topic(topic)
    Observation.unregister_topic(topic)
    all_tables = :ets.all()
    table_name = String.to_atom("eb_ew_#{topic}")

    refute Enum.any?(all_tables, fn t -> t == table_name end)
  end

  test "create and fetch" do
    topic = :some_event_occurred1
    id = "E1"

    subscribers = [
      {InputLogger, %{}},
      {Calculator, %{}},
      {MemoryLeakerOne, %{}},
      {BadOne, %{}}
    ]

    Observation.register_topic(topic)
    Observation.save({topic, id}, {subscribers, [], []})

    assert {subscribers, [], []} == Observation.fetch({topic, id})
  end

  test "complete" do
    topic = :some_event_occurred2
    id = "E1"

    subscribers = [
      {InputLogger, %{}},
      {Calculator, %{}},
      {MemoryLeakerOne, %{}},
      {BadOne, %{}}
    ]

    Observation.register_topic(topic)
    Observation.save({topic, id}, {subscribers, [], []})
    Observation.mark_as_completed({{InputLogger, %{}}, {topic, id}})

    assert {subscribers, [{InputLogger, %{}}], []} == Observation.fetch({topic, id})
  end

  test "skip" do
    id = "E1"
    topic = :some_event_occurred3

    subscribers = [
      {InputLogger, %{}},
      {Calculator, %{}},
      {MemoryLeakerOne, %{}},
      {BadOne, %{}}
    ]

    Observation.register_topic(topic)
    Observation.save({topic, id}, {subscribers, [], []})
    Observation.mark_as_skipped({{InputLogger, %{}}, {topic, id}})

    assert {subscribers, [], [{InputLogger, %{}}]} == Observation.fetch({topic, id})
  end
end
