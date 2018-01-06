defmodule EventBus.EventManagerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias EventBus.Model.Event
  alias EventBus.{EventManager, SubscriptionManager}
  alias EventBus.Support.Helper.{InputLogger, Calculator, MemoryLeakerOne,
    BadOne}
  doctest EventBus.EventManager

  @topic :metrics_received
  @event %Event{id: "E1", transaction_id: "T1", topic: @topic, data: [1, 2]}

  setup do
    Enum.each(SubscriptionManager.subscribers(), fn subscriber ->
      SubscriptionManager.unsubscribe(subscriber)
    end)
    :ok
  end

  test "notify" do
    SubscriptionManager.subscribe({InputLogger,
      ["metrics_received$", "metrics_summed$"]})
    SubscriptionManager.subscribe({BadOne, [".*"]})
    SubscriptionManager.subscribe({Calculator, ["metrics_received$"]})
    SubscriptionManager.subscribe({MemoryLeakerOne, [".*"]})
    listeners = SubscriptionManager.subscribers(@topic)

    logs =
      capture_log(fn ->
       EventManager.notify(listeners, @event)
       Process.sleep(1_000)
      end)

    assert String.contains?(logs, "BadOne.process/1 raised an error!")
    assert String.contains?(logs, "Event log for %EventBus.Model.Event{data: [1, 2], id: \"E1\", initialized_at: nil, occurred_at: nil, topic: :metrics_received, transaction_id: \"T1\", ttl: nil}")
    assert String.contains?(logs, "Event log for %EventBus.Model.Event{data: {3, [1, 2]}, id: \"E123\", initialized_at: nil, occurred_at: nil, topic: :metrics_summed, transaction_id: \"T1\", ttl: nil}")
  end
end
