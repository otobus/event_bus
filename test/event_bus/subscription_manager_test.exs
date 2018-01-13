defmodule EventBus.SubscriptionManagerTest do
  use ExUnit.Case, async: false
  alias EventBus.Support.Helper.{InputLogger, Calculator, MemoryLeakerOne,
    AnotherCalculator}
  alias EventBus.SubscriptionManager
  doctest EventBus.SubscriptionManager

  setup do
    on_exit fn ->
      SubscriptionManager.unregister_topic(:auto_subscribed)
    end

    for {subscriber, _topics} <- SubscriptionManager.subscribers() do
      SubscriptionManager.unsubscribe(subscriber)
    end
    :ok
  end

  test "subscribe" do
    SubscriptionManager.subscribe({{InputLogger, %{}}, [".*"]})
    SubscriptionManager.subscribe({{Calculator, %{}}, [".*"]})
    SubscriptionManager.subscribe({{MemoryLeakerOne, %{}}, [".*"]})
    SubscriptionManager.subscribe({AnotherCalculator, [".*"]})
    Process.sleep(300)

    assert [
      {AnotherCalculator, [".*"]},
      {{MemoryLeakerOne, %{}}, [".*"]},
      {{Calculator, %{}}, [".*"]},
      {{InputLogger, %{}}, [".*"]}
    ] == SubscriptionManager.subscribers()
  end

  test "does not subscribe same listener" do
    SubscriptionManager.subscribe({{InputLogger, %{}}, [".*"]})
    SubscriptionManager.subscribe({{InputLogger, %{}}, [".*"]})
    SubscriptionManager.subscribe({{InputLogger, %{}}, [".*"]})
    Process.sleep(300)

    assert [{{InputLogger, %{}}, [".*"]}] == SubscriptionManager.subscribers()
  end

  test "unsubscribe" do
    SubscriptionManager.subscribe({{InputLogger, %{}}, [".*"]})
    SubscriptionManager.subscribe({{Calculator, %{}}, [".*"]})
    SubscriptionManager.subscribe({{MemoryLeakerOne, %{}}, [".*"]})
    SubscriptionManager.subscribe({AnotherCalculator, [".*"]})
    SubscriptionManager.unsubscribe({Calculator, %{}})
    SubscriptionManager.unsubscribe(AnotherCalculator)
    Process.sleep(300)

    assert [{{MemoryLeakerOne, %{}}, [".*"]}, {{InputLogger, %{}}, [".*"]}] ==
      SubscriptionManager.subscribers()
  end

  test "register_topic auto subscribe workers" do
    topic = :auto_subscribed

    SubscriptionManager.subscribe({{InputLogger, %{}}, [".*"]})
    SubscriptionManager.subscribe({{Calculator, %{}}, [".*"]})
    SubscriptionManager.subscribe({{MemoryLeakerOne, %{}}, ["other_received$"]})
    SubscriptionManager.subscribe({AnotherCalculator, [".*"]})

    SubscriptionManager.register_topic(topic)

    Process.sleep(300)

    assert [{InputLogger, %{}}, {Calculator, %{}}, AnotherCalculator] ==
      SubscriptionManager.subscribers(topic)
  end

  test "unregister_topic delete subscribers" do
    topic = :auto_subscribed

    SubscriptionManager.subscribe({{InputLogger, %{}}, [".*"]})
    SubscriptionManager.subscribe({{Calculator, %{}}, [".*"]})
    SubscriptionManager.subscribe({{MemoryLeakerOne, %{}}, ["other_received$"]})
    SubscriptionManager.subscribe({AnotherCalculator, [".*"]})

    SubscriptionManager.register_topic(topic)
    SubscriptionManager.unregister_topic(topic)
    Process.sleep(300)

    assert [] == SubscriptionManager.subscribers(topic)
  end

  test "subscribers" do
    SubscriptionManager.subscribe({{InputLogger, %{}}, [".*"]})
    Process.sleep(300)

    assert [{{InputLogger, %{}}, [".*"]}] == SubscriptionManager.subscribers()
  end

  test "subscribers with event type" do
    SubscriptionManager.subscribe({{InputLogger, %{}}, [".*"]})
    Process.sleep(300)

    assert [{InputLogger, %{}}] ==
      SubscriptionManager.subscribers(:metrics_received)
    assert [{InputLogger, %{}}] ==
      SubscriptionManager.subscribers(:metrics_summed)
  end

  test "subscribers with event type and without config" do
    SubscriptionManager.subscribe({AnotherCalculator, [".*"]})
    Process.sleep(300)

    assert [AnotherCalculator] ==
      SubscriptionManager.subscribers(:metrics_received)
    assert [AnotherCalculator] ==
      SubscriptionManager.subscribers(:metrics_summed)
  end

  test "state persistency to Application environment" do
    SubscriptionManager.subscribe({{InputLogger, %{}}, ["metrics_received",
      "metrics_summed"]})
    SubscriptionManager.subscribe({AnotherCalculator, ["metrics_received$"]})
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
