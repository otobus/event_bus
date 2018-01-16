defmodule EventBus.Service.NotifierTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias EventBus.Model.Event
  alias EventBus.Service.Notifier
  alias EventBus.Subscription
  alias EventBus.Support.Helper.{InputLogger, Calculator, AnotherCalculator,
    MemoryLeakerOne, BadOne}

  doctest Notifier

  @topic :metrics_received
  @event %Event{id: "E1", transaction_id: "T1", topic: @topic, data: [1, 2],
    source: "NotifierTest"}

  setup do
    for subscriber <- Subscription.subscribers() do
      Subscription.unsubscribe(subscriber)
    end

    Process.sleep(100)
    :ok
  end

  test "notify" do
    Subscription.subscribe({{InputLogger, %{}},
      ["metrics_received$", "metrics_summed$"]})
    Subscription.subscribe({{BadOne, %{}}, [".*"]})
    Subscription.subscribe({{Calculator, %{}}, ["metrics_received$"]})
    Subscription.subscribe({{MemoryLeakerOne, %{}}, [".*"]})

    # This processor/listener one has one config!!!
    Subscription.subscribe({AnotherCalculator, ["metrics_received$"]})

    Process.sleep(300) # Sleep until subscriptions complete

    logs =
      capture_log(fn ->
        Notifier.notify(@event)
        Process.sleep(300)
      end)

    assert String.contains?(logs, "BadOne.process/1 raised an error!")
    assert String.contains?(logs, "Event log for %EventBus.Model.Event{data: [1, 2], id: \"E1\", initialized_at: nil, occurred_at: nil, source: \"NotifierTest\", topic: :metrics_received, transaction_id: \"T1\", ttl: nil}")
    assert String.contains?(logs, "Event log for %EventBus.Model.Event{data: {3, [1, 2]}, id: \"E123\", initialized_at: nil, occurred_at: nil, source: \"Logger\", topic: :metrics_summed, transaction_id: \"T1\", ttl: nil}")
    assert String.contains?(logs, "Event log for %EventBus.Model.Event{data: {3, [1, 2]}, id: \"E123\", initialized_at: nil, occurred_at: nil, source: \"AnotherCalculator\", topic: :metrics_summed, transaction_id: \"T1\", ttl: nil}")
  end
end
