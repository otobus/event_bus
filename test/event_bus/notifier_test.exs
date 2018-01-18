defmodule EventBus.NotifierTest do
  use ExUnit.Case, async: false
  alias EventBus.Model.Event
  alias EventBus.Notifier

  doctest Notifier

  @topic :metrics_received
  @event %Event{
    id: "E1",
    transaction_id: "T1",
    topic: @topic,
    data: [1, 2],
    source: "NotifierTest"
  }

  setup do
    refute is_nil(Process.whereis(Notifier))
    :ok
  end

  test "notify" do
    assert :ok == Notifier.notify(@event)
  end
end
