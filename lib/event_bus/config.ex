defmodule EventBus.Config do
  @moduledoc """
  EventBus config reader
  """

  @doc """
  Fetch list of registered event topics
  """
  def topics,
    do: Application.get_env(:event_bus, :topics, [])
end
