defmodule EventBus.Service.TopicTest do
  use ExUnit.Case, async: false
  alias EventBus.Service.Topic

  @sys_topic :eb_action_called

  doctest Topic

  setup do
    on_exit(fn ->
      Topic.unregister(:t1)
      Topic.unregister(:t2)
      Topic.unregister(:t3)
    end)

    :ok
  end

  test "register_topic" do
    topic = :t1
    Topic.register(topic)
    Process.sleep(10)
    all_tables = :ets.all()

    assert Enum.any?(Topic.all(), fn t -> t == topic end)
    assert Enum.any?(all_tables, fn t -> t == :"eb_es_#{topic}" end)
    assert Enum.any?(all_tables, fn t -> t == :"eb_ew_#{topic}" end)
  end

  test "register_topic does not re-register same topic" do
    topic = :t2
    Topic.register(topic)
    Process.sleep(10)
    topic_count = length(Topic.all())

    Topic.register(topic)
    Process.sleep(10)

    assert topic_count == length(Topic.all())
  end

  test "unregister_topic" do
    topic = :t3
    Topic.register(topic)
    Topic.unregister(topic)
    Process.sleep(10)
    all_tables = :ets.all()

    refute Enum.any?(Topic.all(), fn t -> t == topic end)
    refute Enum.any?(all_tables, fn t -> t == :"eb_es_#{topic}" end)
    refute Enum.any?(all_tables, fn t -> t == :"eb_ew_#{topic}" end)
  end

  test "all" do
    topic = :t3
    Topic.register(topic)
    Process.sleep(10)
    assert [:t3, @sys_topic, :metrics_received, :metrics_summed] == Topic.all()
  end

  test "exist? with an existent topic" do
    assert Topic.exist?(:metrics_received)
  end

  test "exist? with a non-existent topic" do
    refute Topic.exist?(:unknown_called)
  end
end
