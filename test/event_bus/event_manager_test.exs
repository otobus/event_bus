defmodule EventBus.EventManagerTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias EventBus.{EventManager, SubscriptionManager}
  alias Helper.{InputLogger, Calculator, MemoryLeakerOne, BadOne}
  doctest EventBus.EventManager

  @event {:metrics_received, [1, 2, 3, 4, 5]}

  setup do
    Enum.each(SubscriptionManager.subscribers(), fn subscriber ->
      SubscriptionManager.unsubscribe(subscriber)
    end)
  end

  test "notify" do
    SubscriptionManager.subscribe(InputLogger)
    SubscriptionManager.subscribe(Calculator)
    SubscriptionManager.subscribe(MemoryLeakerOne)
    listeners = SubscriptionManager.subscribers()

    logs = capture_log(fn ->
       EventManager.notify(listeners, @event)
       Process.sleep(1_000)
      end)

    assert String.contains?(logs, "Event log 'metrics_received' for [1, 2, 3, 4, 5]")
    assert String.contains?(logs, "Event log 'metrics_summed' for {15, [1, 2, 3, 4, 5]")
  end

  test "notify with bad listener" do
    SubscriptionManager.subscribe(InputLogger)
    SubscriptionManager.subscribe(BadOne)
    SubscriptionManager.subscribe(Calculator)
    listeners = SubscriptionManager.subscribers()

    logs = capture_log(fn ->
       EventManager.notify(listeners, @event)
       Process.sleep(1_000)
      end)

    assert String.contains?(logs, "Helper.BadOne.process/1 raised an error!")
    assert String.contains?(logs, "Event log 'metrics_received' for [1, 2, 3, 4, 5]")
    assert String.contains?(logs, "Event log 'metrics_summed' for {15, [1, 2, 3, 4, 5]")
  end
end
