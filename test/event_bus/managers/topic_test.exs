defmodule EventBus.Manager.TopicTest do
  use ExUnit.Case, async: false
  alias EventBus.Manager.Topic

  doctest Topic

  setup do
    on_exit(fn ->
      topics = [:t1, :t2]
      Enum.each(topics, fn topic -> Topic.unregister(topic) end)
    end)

    :ok
  end

  test "register_topic" do
    assert :ok == Topic.register(:t1)
  end

  test "unregister_topic" do
    topic = :t2
    Topic.register(topic)

    assert :ok == Topic.unregister(topic)
  end
end
