defmodule EventBus.SubscriptionTest do
  use ExUnit.Case, async: false
  alias EventBus.Support.Helper.{InputLogger, AnotherCalculator}
  alias EventBus.Subscription

  doctest Subscription

  setup do
    on_exit(fn ->
      Subscription.unregister_topic(:auto_subscribed)
    end)

    for {subscriber, _topics} <- Subscription.subscribers() do
      Subscription.unsubscribe(subscriber)
    end

    :ok
  end

  test "subscribe" do
    assert :ok == Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    assert :ok == Subscription.subscribe({AnotherCalculator, [".*"]})
  end

  test "unsubscribe" do
    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    Subscription.subscribe({AnotherCalculator, [".*"]})

    assert :ok == Subscription.unsubscribe({InputLogger, %{}})
    assert :ok == Subscription.unsubscribe(AnotherCalculator)
  end

  test "register_topic" do
    assert :ok == Subscription.register_topic(:auto_subscribed)
  end

  test "unregister_topic" do
    topic = :auto_subscribed
    Subscription.register_topic(topic)

    assert :ok == Subscription.unregister_topic(topic)
  end
end
