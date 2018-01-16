defmodule EventBus.Service.SubscriptionTest do
  use ExUnit.Case, async: false
  alias EventBus.Support.Helper.{InputLogger, Calculator, MemoryLeakerOne,
    AnotherCalculator}
  alias EventBus.Service.Subscription

  doctest Subscription

  setup do
    on_exit fn ->
      Subscription.unregister_topic(:auto_subscribed)
    end

    for {subscriber, _topics} <- Subscription.subscribers() do
      Subscription.unsubscribe(subscriber)
    end
    :ok
  end

  test "subscribe" do
    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    Subscription.subscribe({{Calculator, %{}}, [".*"]})
    Subscription.subscribe({{MemoryLeakerOne, %{}}, [".*"]})
    Subscription.subscribe({AnotherCalculator, [".*"]})
    Process.sleep(300)

    assert [
      {AnotherCalculator, [".*"]},
      {{MemoryLeakerOne, %{}}, [".*"]},
      {{Calculator, %{}}, [".*"]},
      {{InputLogger, %{}}, [".*"]}
    ] == Subscription.subscribers()
  end

  test "does not subscribe same listener" do
    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    Process.sleep(300)

    assert [{{InputLogger, %{}}, [".*"]}] == Subscription.subscribers()
  end

  test "unsubscribe" do
    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    Subscription.subscribe({{Calculator, %{}}, [".*"]})
    Subscription.subscribe({{MemoryLeakerOne, %{}}, [".*"]})
    Subscription.subscribe({AnotherCalculator, [".*"]})
    Subscription.unsubscribe({Calculator, %{}})
    Subscription.unsubscribe(AnotherCalculator)
    Process.sleep(300)

    assert [{{MemoryLeakerOne, %{}}, [".*"]}, {{InputLogger, %{}}, [".*"]}] ==
      Subscription.subscribers()
  end

  test "register_topic auto subscribe workers" do
    topic = :auto_subscribed

    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    Subscription.subscribe({{Calculator, %{}}, [".*"]})
    Subscription.subscribe({{MemoryLeakerOne, %{}}, ["other_received$"]})
    Subscription.subscribe({AnotherCalculator, [".*"]})

    Subscription.register_topic(topic)

    Process.sleep(300)

    assert [{InputLogger, %{}}, {Calculator, %{}}, AnotherCalculator] ==
      Subscription.subscribers(topic)
  end

  test "unregister_topic delete subscribers" do
    topic = :auto_subscribed

    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    Subscription.subscribe({{Calculator, %{}}, [".*"]})
    Subscription.subscribe({{MemoryLeakerOne, %{}}, ["other_received$"]})
    Subscription.subscribe({AnotherCalculator, [".*"]})

    Subscription.register_topic(topic)
    Subscription.unregister_topic(topic)
    Process.sleep(300)

    assert [] == Subscription.subscribers(topic)
  end

  test "subscribers" do
    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    Process.sleep(300)

    assert [{{InputLogger, %{}}, [".*"]}] == Subscription.subscribers()
  end

  test "subscribers with event type" do
    Subscription.subscribe({{InputLogger, %{}}, [".*"]})
    Process.sleep(300)

    assert [{InputLogger, %{}}] ==
      Subscription.subscribers(:metrics_received)
    assert [{InputLogger, %{}}] ==
      Subscription.subscribers(:metrics_summed)
  end

  test "subscribers with event type and without config" do
    Subscription.subscribe({AnotherCalculator, [".*"]})
    Process.sleep(300)

    assert [AnotherCalculator] ==
      Subscription.subscribers(:metrics_received)
    assert [AnotherCalculator] ==
      Subscription.subscribers(:metrics_summed)
  end

  test "state persistency to Application environment" do
    Subscription.subscribe({{InputLogger, %{}}, ["metrics_received",
      "metrics_summed"]})
    Subscription.subscribe({AnotherCalculator, ["metrics_received$"]})
    Process.sleep(300)
    expected = {
      [
        {AnotherCalculator, ["metrics_received$"]},
        {{InputLogger, %{}}, ["metrics_received", "metrics_summed"]}
      ],
      %{
        metrics_received: [AnotherCalculator, {InputLogger, %{}}],
        metrics_summed: [{InputLogger, %{}}]}
      }

    assert expected == Application.get_env(:event_bus, :subscriptions)
  end
end
