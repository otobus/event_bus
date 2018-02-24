defmodule EventBus.Service.ObservationTest do
  use ExUnit.Case, async: false
  alias EventBus.Service.{Observation, Topic}
  alias EventBus.Support.Helper.{
    InputLogger,
    Calculator,
    MemoryLeakerOne,
    BadOne
  }

  doctest Observation

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
    Observation.register_topic(topic)

    assert Observation.exist?(topic)
  end

  test "register_topic" do
    topic = :metrics_destroyed
    Observation.register_topic(topic)
    all_tables = :ets.all()

    assert Enum.any?(all_tables, fn t -> t == :"eb_ew_#{topic}" end)
  end

  test "unregister_topic" do
    topic = :metrics_destroyed
    Observation.register_topic(topic)
    Observation.unregister_topic(topic)
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

    Observation.register_topic(topic)
    Observation.save({topic, id}, {listeners, [], []})

    assert {listeners, [], []} == Observation.fetch({topic, id})
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

    Observation.register_topic(topic)
    Observation.save({topic, id}, {listeners, [], []})
    Observation.mark_as_completed({{InputLogger, %{}}, topic, id})

    assert {listeners, [{InputLogger, %{}}], []} == Observation.fetch({topic, id})
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

    Observation.register_topic(topic)
    Observation.save({topic, id}, {listeners, [], []})
    Observation.mark_as_skipped({{InputLogger, %{}}, topic, id})

    assert {listeners, [], [{InputLogger, %{}}]} == Observation.fetch({topic, id})
  end
end