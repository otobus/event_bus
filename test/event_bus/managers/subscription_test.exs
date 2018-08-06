defmodule EventBus.Manager.SubscriptionTest do
  use ExUnit.Case, async: false

  alias EventBus.Manager.Subscription
  alias EventBus.Support.Helper.{AnotherCalculator, InputLogger}

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

  test "subscribed?" do
    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    assert Subscription.subscribed?({{InputLogger, %{}}, [".*"]})
    refute Subscription.subscribed?({InputLogger, [".*"]})
  end

  test "subscribe" do
    assert :ok == Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    assert Subscription.subscribed?({{InputLogger, %{}}, [".*"]})

    assert :ok == Subscription.subscribe({AnotherCalculator, [".*"]})
    assert Subscription.subscribed?({AnotherCalculator, [".*"]})
  end

  test "unsubscribe" do
    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    Subscription.subscribe({AnotherCalculator, [".*"]})

    assert :ok == Subscription.unsubscribe({InputLogger, %{}})
    refute Subscription.subscribed?({{InputLogger, %{}}, [".*"]})

    assert :ok == Subscription.unsubscribe(AnotherCalculator)
    refute Subscription.subscribed?({AnotherCalculator, [".*"]})
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
