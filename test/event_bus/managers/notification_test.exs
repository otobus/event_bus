defmodule EventBus.Manager.NotificationTest do
  use ExUnit.Case, async: false
  alias EventBus.Model.Event
  alias EventBus.Manager.Notification

  doctest Notification

  @topic :metrics_received
  @event %Event{
    id: "E1",
    transaction_id: "T1",
    topic: @topic,
    data: [1, 2],
    source: "NotifierTest"
  }

  setup do
    refute is_nil(Process.whereis(Notification))
    :ok
  end

  test "notify" do
    assert :ok == Notification.notify(@event)
  end
end
