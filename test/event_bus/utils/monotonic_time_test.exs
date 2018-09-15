defmodule EventBus.Util.MonotonicTimeTest do
  use ExUnit.Case

  alias EventBus.Util.MonotonicTime

  test "now should return int" do
    assert is_integer(MonotonicTime.now())
  end

  test "now should increase on every call" do
    assert MonotonicTime.now() <= MonotonicTime.now()
  end

  test "now does not change init_time configuration on multiple calls" do
    # First call
    MonotonicTime.now()
    init_time = Application.get_env(:event_bus, :init_time) # init_time

    # Second call
    MonotonicTime.now()
    assert init_time == Application.get_env(:event_bus, :init_time)
  end
end
