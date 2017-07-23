defmodule EventBusTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  doctest EventBus

  @event {:metrics_received, [1, 2]}

  test "notify" do
    EventBus.subscribe(Helper.InputLogger)
    EventBus.subscribe(Helper.Calculator)
    EventBus.subscribe(Helper.MemoryLeakerOne)

    logs = capture_log(fn ->
       EventBus.notify(@event)
       Process.sleep(1_000)
      end)

    assert String.contains?(logs, "Event log 'metrics_received' for [1, 2]")
    assert String.contains?(logs, "Event log 'metrics_summed' for {3, [1, 2]")
  end
end
