defmodule EventBusrTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias EventBus.Support.Helper.{InputLogger, Calculator, MemoryLeakerOne,
    BadOne}
  doctest EventBus.EventManager

  @event {:metrics_received, [1, 7]}

  setup do
    Enum.each(EventBus.subscribers(), fn subscriber ->
      EventBus.unsubscribe(subscriber)
    end)
    :ok
  end

  test "notify" do
    EventBus.subscribe(InputLogger)
    EventBus.subscribe(BadOne)
    EventBus.subscribe(Calculator)
    EventBus.subscribe(MemoryLeakerOne)

    logs =
      capture_log(fn ->
       EventBus.notify(@event)
       Process.sleep(1_000)
      end)

    assert String.contains?(logs, "BadOne.process/1 raised an error!")
    assert String.contains?(logs, "Event log 'metrics_received' for [1, 7]")
    assert String.contains?(logs, "Event log 'metrics_summed' for {8, [1, 7]")
  end
end
