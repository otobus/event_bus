defmodule EventBus.SubscriptionManagerTest do
  use ExUnit.Case, async: false
  alias Helper.{InputLogger, Calculator, MemoryLeakerOne}
  alias EventBus.SubscriptionManager
  doctest EventBus.SubscriptionManager

  setup do
    Enum.each(SubscriptionManager.subscribers(), fn subscriber ->
      SubscriptionManager.unsubscribe(subscriber)
    end)
  end

  test "subscribe" do
    SubscriptionManager.subscribe(InputLogger)
    SubscriptionManager.subscribe(Calculator)
    SubscriptionManager.subscribe(MemoryLeakerOne)
    Process.sleep(1_000)

    assert [MemoryLeakerOne, Calculator, InputLogger] ==
      SubscriptionManager.subscribers()
  end

  test "unsubscribe" do
    SubscriptionManager.subscribe(InputLogger)
    SubscriptionManager.subscribe(Calculator)
    SubscriptionManager.subscribe(MemoryLeakerOne)
    SubscriptionManager.unsubscribe(Calculator)
    Process.sleep(1_000)

    assert [MemoryLeakerOne, InputLogger] == SubscriptionManager.subscribers()
  end

  test "subscribers" do
    SubscriptionManager.subscribe(InputLogger)
    Process.sleep(1_000)

    assert [InputLogger] == SubscriptionManager.subscribers()
  end
end
