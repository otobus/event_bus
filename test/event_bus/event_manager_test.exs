defmodule EventBus.EventManagerTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias EventBus.Model.Event
  alias EventBus.{EventManager, SubscriptionManager}
  alias EventBus.Support.Helper.{InputLogger, Calculator, AnotherCalculator,
    MemoryLeakerOne, BadOne}
  doctest EventBus.EventManager

  @topic :metrics_received
  @event %Event{id: "E1", transaction_id: "T1", topic: @topic, data: [1, 2],
    source: "EventManagerTest"}

  setup do
    Process.sleep(100)
    Enum.each(SubscriptionManager.subscribers(), fn subscriber ->
      SubscriptionManager.unsubscribe(subscriber)
    end)
    :ok
  end

  test "notify" do
    SubscriptionManager.subscribe({{InputLogger, %{}},
      ["metrics_received$", "metrics_summed$"]})
    SubscriptionManager.subscribe({{BadOne, %{}}, [".*"]})
    SubscriptionManager.subscribe({{Calculator, %{}}, ["metrics_received$"]})
    SubscriptionManager.subscribe({{MemoryLeakerOne, %{}}, [".*"]})

    # This processor/listener one has one config!!!
    SubscriptionManager.subscribe({AnotherCalculator, ["metrics_received$"]})
    listeners = SubscriptionManager.subscribers(@topic)

    logs =
      capture_log(fn ->
       EventManager.notify(listeners, @event)
       Process.sleep(300)
      end)

    assert String.contains?(logs, "BadOne.process/1 raised an error!")
    assert String.contains?(logs, "Event log for %EventBus.Model.Event{data: [1, 2], id: \"E1\", initialized_at: nil, occurred_at: nil, source: \"EventManagerTest\", topic: :metrics_received, transaction_id: \"T1\", ttl: nil}")
    assert String.contains?(logs, "Event log for %EventBus.Model.Event{data: {3, [1, 2]}, id: \"E123\", initialized_at: nil, occurred_at: nil, source: \"Logger\", topic: :metrics_summed, transaction_id: \"T1\", ttl: nil}")
    assert String.contains?(logs, "Event log for %EventBus.Model.Event{data: {3, [1, 2]}, id: \"E123\", initialized_at: nil, occurred_at: nil, source: \"AnotherCalculator\", topic: :metrics_summed, transaction_id: \"T1\", ttl: nil}")
  end
end
