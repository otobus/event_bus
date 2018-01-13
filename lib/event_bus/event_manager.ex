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
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  @spec notify(list(module()), Event.t) :: no_return()
  def notify(listeners, event),
    do: GenServer.cast(__MODULE__, {:notify, listeners, event})

  @doc false
  @spec handle_cast(tuple(), nil) :: no_return()
  def handle_cast({:notify, listeners, %Event{id: id, topic: topic} = event},
    state) do
    :ok = EventStore.save(event)
    :ok = EventWatcher.create({listeners, topic, id})

    notify_listeners(listeners, {topic, id})
    {:noreply, state}
  end

  @spec notify_listeners(list(), tuple()) :: no_return()
  defp notify_listeners(listeners, event_shadow) do
    for listener <- listeners do
      notify_listener(listener, event_shadow)
    end
  end

  @spec notify_listener(tuple(), tuple()) :: no_return()
  @spec notify_listener(module(), tuple()) :: no_return()
  defp notify_listener({listener, config}, {topic, id}) do
    listener.process({config, topic, id})
  rescue
    error ->
      log(listener, error)
      EventWatcher.mark_as_skipped({{listener, config}, topic, id})
  end
  defp notify_listener(listener, {topic, id}) do
    listener.process({topic, id})
  rescue
    error ->
      log(listener, error)
      EventWatcher.mark_as_skipped({listener, topic, id})
  end

  @spec log(module(), any()) :: no_return()
  defp log(listener, error) do
    msg = "#{listener}.process/1 raised an error!\n#{inspect(error)}"
    Logger.log(@logging_level, msg)
  end
end
