defmodule EventBus.TopicManagerTest do
  use ExUnit.Case, async: false
  alias EventBus.Config
  alias EventBus.TopicManager

  doctest EventBus.TopicManager

  setup do
    on_exit fn ->
      TopicManager.unregister(:t1)
      TopicManager.unregister(:t2)
      TopicManager.unregister(:t3)
    end

    :ok
  end

  test "register_topic" do
    topic = :t1
    TopicManager.register(topic)
    Process.sleep(10)
    all_tables = :ets.all()

    assert Enum.any?(Config.topics(), fn t -> t == topic end)
    assert Enum.any?(all_tables, fn t -> t == :"eb_es_#{topic}" end)
    assert Enum.any?(all_tables, fn t -> t == :"eb_ew_#{topic}" end)
  end

  test "register_topic does not re-register same topic" do
    topic = :t2
    TopicManager.register(topic)
    Process.sleep(10)
    topic_count = length(Config.topics())

    TopicManager.register(topic)
    Process.sleep(10)

    assert topic_count == length(Config.topics())
  end

  test "unregister_topic" do
    topic = :t3
    TopicManager.register(topic)
    TopicManager.unregister(topic)
    Process.sleep(10)
    all_tables = :ets.all()

    refute Enum.any?(Config.topics(), fn t -> t == topic end)
    refute Enum.any?(all_tables, fn t -> t == :"eb_es_#{topic}" end)
    refute Enum.any?(all_tables, fn t -> t == :"eb_ew_#{topic}" end)
  end
end
