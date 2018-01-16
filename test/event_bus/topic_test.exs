defmodule EventBus.TopicTest do
  use ExUnit.Case, async: false
  alias EventBus.Topic

  doctest EventBus.Topic

  setup do
    on_exit fn ->
      Topic.unregister(:t1)
      Topic.unregister(:t2)
    end

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
