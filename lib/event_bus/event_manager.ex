defmodule EventBus.EventManager do
  @moduledoc """
  Event Manager
  """

  require Logger
  use GenServer

  @logging_level :info

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def notify(listeners, {_event_type, _event_data} = event) do
    GenServer.cast(__MODULE__, {:notify, listeners, event})
  end

  @doc false
  def handle_cast({:notify, listeners, event}, state) do
    Enum.each(listeners, fn listener ->
      notify_listener(listener, event)
    end)
    {:noreply, state}
  end

  defp notify_listener(listener, event) do
    try do
      listener.process(event)
    rescue
      err ->
        Logger.log(@logging_level,
          fn -> "#{listener}.process/1 raised an error!\n#{inspect(err)}" end)
    end
  end
end
