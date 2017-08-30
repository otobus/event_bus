defmodule EventBus.EventManager do
  @moduledoc """
  Event Manager
  """

  require Logger
  use GenServer
  alias EventBus.EventStore
  alias EventBus.EventWatcher
  alias EventBus.Model.Event

  @logging_level :info

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec notify(list(module()), Event.t) :: no_return()
  @doc false
  def notify(listeners, event) do
    GenServer.cast(__MODULE__, {:notify, listeners, event})
  end

  @doc false
  @spec handle_cast(tuple(), nil) :: no_return()
  def handle_cast({:notify, listeners, %Event{id: id, topic: topic} = event},
    state) do
    :ok = EventStore.save(event)
    :ok = EventWatcher.create({listeners, topic, id})

    notify_listeners(listeners, {topic, id})
    {:noreply, state}
  end

  @spec notify_listeners(list(module()), tuple()) :: no_return()
  defp notify_listeners(listeners, event_shadow) do
    Enum.each(listeners, fn listener ->
      notify_listener(listener, event_shadow)
    end)
  end

  @spec notify_listener(module(), tuple()) :: no_return()
  defp notify_listener(listener, {topic, id}) do
    listener.process({topic, id})
  rescue
    err ->
      Logger.log(@logging_level,
        fn -> "#{listener}.process/1 raised an error!\n#{inspect(err)}" end)
      EventWatcher.mark_as_skipped({listener, topic, id})
  end
end
