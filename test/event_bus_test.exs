defmodule EventBusTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias EventBus.Model.Event
  alias EventBus.Support.Helper.{InputLogger, Calculator, MemoryLeakerOne,
    BadOne}
  doctest EventBus.EventManager

  @event %Event{id: "M1", transaction_id: "T1", data: [1, 7],
    topic: :metrics_received, source: "EventBusTest"}

  setup do
    Enum.each(EventBus.subscribers(), fn subscriber ->
      EventBus.unsubscribe(subscriber)
    end)
    :ok
  end

  test "notify" do
    EventBus.subscribe({{InputLogger, %{}}, [".*"]})
    EventBus.subscribe({{BadOne, %{}}, [".*"]})
    EventBus.subscribe({{Calculator, %{}}, ["metrics_received"]})
    EventBus.subscribe({{MemoryLeakerOne, %{}}, [".*"]})

    logs =
      capture_log(fn ->
       EventBus.notify(@event)
       Process.sleep(1_000)
      end)

    assert String.contains?(logs, "BadOne.process/1 raised an error!")
    assert String.contains?(logs, "Event log for %EventBus.Model.Event{data:" <>
      " [1, 7], id: \"M1\", initialized_at: nil, occurred_at: nil," <>
      " source: \"EventBusTest\", topic: :metrics_received," <>
      " transaction_id: \"T1\", ttl: nil}")
    assert String.contains?(logs, "Event log for %EventBus.Model.Event{data:" <>
      " {8, [1, 7]}, id: \"E123\", initialized_at: nil, occurred_at: nil," <>
      " source: \"Logger\", topic: :metrics_summed," <>
      " transaction_id: \"T1\", ttl: nil}")
  end

  test "topic_exist? with an existent topic" do
    assert EventBus.topic_exist? :metrics_received
  end

  test "topic_exist? with a non-existent topic" do
    refute EventBus.topic_exist? :unknown_called
  end
end
