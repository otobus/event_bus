defmodule EventBus.Service.TopicTest do
  use ExUnit.Case, async: false
  alias EventBus.Service.Topic

  doctest Topic

  setup do
    on_exit(fn ->
      topics = Topic.all() -- [:metrics_received, :metrics_summed]
      Enum.each(topics, fn topic -> Topic.unregister(topic) end)
    end)

    :ok
  end

  test "exist?" do
    topic = :metrics_received_1
    Topic.register(topic)

    assert Topic.exist?(topic)
  end

  test "register_topic" do
    topic = :t1
    Topic.register(topic)
    all_tables = :ets.all()

    store_table_name = String.to_atom("eb_es_#{topic}")
    watcher_table_name = String.to_atom("eb_ew_#{topic}")

    assert Enum.any?(Topic.all(), fn t -> t == topic end)
    assert Enum.any?(all_tables, fn t -> t == store_table_name end)
    assert Enum.any?(all_tables, fn t -> t == watcher_table_name end)
  end

  test "register_topic does not re-register same topic" do
    topic = :t2
    Topic.register(topic)
    topic_count = length(Topic.all())
    Topic.register(topic)

    assert topic_count == length(Topic.all())
  end

  test "unregister_topic" do
    topic = :t3
    Topic.register(topic)
    Topic.unregister(topic)
    all_tables = :ets.all()

    store_table_name = String.to_atom("eb_es_#{topic}")
    watcher_table_name = String.to_atom("eb_ew_#{topic}")

    refute Enum.any?(Topic.all(), fn t -> t == topic end)
    refute Enum.any?(all_tables, fn t -> t == store_table_name end)
    refute Enum.any?(all_tables, fn t -> t == watcher_table_name end)
  end

  test "all" do
    topic = :t3
    Topic.register(topic)
    assert [:t3, :metrics_received, :metrics_summed] == Topic.all()
  end

  test "exist? with an existent topic" do
    assert Topic.exist?(:metrics_received)
  end

  test "exist? with a non-existent topic" do
    refute Topic.exist?(:unknown_called)
  end
end
