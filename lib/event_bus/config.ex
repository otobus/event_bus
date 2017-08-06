defmodule EventBus.Config do
  @moduledoc """
  EventBus config reader
  """

  @doc """
  Fetch list of registered events
  """
  def events,
    do: Application.get_env(:event_bus, :events, [])
end
