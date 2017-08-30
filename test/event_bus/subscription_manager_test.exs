defmodule EventBus.SubscriptionManagerTest do
  use ExUnit.Case
  alias EventBus.Support.Helper.{InputLogger, Calculator, MemoryLeakerOne}
  alias EventBus.SubscriptionManager
  doctest EventBus.SubscriptionManager

  setup do
    subscribers = SubscriptionManager.subscribers()
    Enum.each(subscribers, fn {subscriber, _topics} ->
      SubscriptionManager.unsubscribe(subscriber)
    end)
    :ok
  end

  test "subscribe" do
    SubscriptionManager.subscribe({InputLogger, [".*"]})
    SubscriptionManager.subscribe({Calculator, [".*"]})
    SubscriptionManager.subscribe({MemoryLeakerOne, [".*"]})
    Process.sleep(1_000)

    assert [{MemoryLeakerOne, [".*"]}, {Calculator, [".*"]},
      {InputLogger, [".*"]}] == SubscriptionManager.subscribers()
  end

  test "does not subscribe same listener" do
    SubscriptionManager.subscribe({InputLogger, [".*"]})
    SubscriptionManager.subscribe({InputLogger, [".*"]})
    SubscriptionManager.subscribe({InputLogger, [".*"]})
    Process.sleep(1_000)

    assert [{InputLogger, [".*"]}] == SubscriptionManager.subscribers()
  end

  test "unsubscribe" do
    SubscriptionManager.subscribe({InputLogger, [".*"]})
    SubscriptionManager.subscribe({Calculator, [".*"]})
    SubscriptionManager.subscribe({MemoryLeakerOne, [".*"]})
    SubscriptionManager.unsubscribe(Calculator)
    Process.sleep(1_000)

    assert [{MemoryLeakerOne, [".*"]}, {InputLogger, [".*"]}] ==
      SubscriptionManager.subscribers()
  end

  test "subscribers" do
    SubscriptionManager.subscribe({InputLogger, [".*"]})
    Process.sleep(1_000)

    assert [{InputLogger, [".*"]}] == SubscriptionManager.subscribers()
  end

  test "subscribers with event type" do
    SubscriptionManager.subscribe({InputLogger, [".*"]})
    Process.sleep(1_000)

    assert [InputLogger] == SubscriptionManager.subscribers(:metrics_received)
    assert [InputLogger] == SubscriptionManager.subscribers(:metrics_summed)
  end

  test "state persistency to Application environment" do
    SubscriptionManager.subscribe({InputLogger, ["metrics_received",
      "metrics_summed"]})
    Process.sleep(1_000)
    expected = {[{InputLogger, ["metrics_received", "metrics_summed"]}],
      %{metrics_received: [InputLogger], metrics_summed: [InputLogger]}}

    assert expected == Application.get_env(:event_bus, :subscriptions)
  end
end
