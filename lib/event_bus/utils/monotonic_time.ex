defmodule EventBus.Util.MonotonicTime do
  @moduledoc false

  @eb_app :event_bus

  @doc """
  Calculates monotonically increasing current time.
  """
  @spec now() :: integer()
  def now do
    init_time() + monotonic_time()
  end

  defp init_time do
    case Application.get_env(@eb_app, :init_time) do
      nil ->
        time = os_time() - monotonic_time()
        save_init_time(time)

      time ->
        time
    end
  end

  defp save_init_time(time) do
    Application.put_env(@eb_app, :init_time, time, persistent: true)
    time
  end

  defp os_time do
    time_unit = Application.get_env(@eb_app, :time_unit, :microsecond)
    System.os_time(time_unit)
  end

  defp monotonic_time do
    time_unit = Application.get_env(@eb_app, :time_unit, :microsecond)
    System.monotonic_time(time_unit)
  end
end
