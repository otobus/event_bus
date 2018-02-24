defmodule EventBus.Service.Notification do
  @moduledoc false

  require Logger
  alias EventBus.Manager.{Observation, Store, Subscription}
  alias EventBus.Model.Event

  @logging_level :info

  @doc false
  @spec notify(Event.t()) :: no_return()
  def notify(%Event{id: id, topic: topic} = event) do
    listeners = Subscription.subscribers(topic)
    :ok = Store.save(event)
    :ok = Observation.create({listeners, topic, id})

    notify_listeners(listeners, {topic, id})
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
      Observation.mark_as_skipped({{listener, config}, topic, id})
  end

  defp notify_listener(listener, {topic, id}) do
    listener.process({topic, id})
  rescue
    error ->
      log(listener, error)
      Observation.mark_as_skipped({listener, topic, id})
  end

  @spec log(module(), any()) :: no_return()
  defp log(listener, error) do
    msg = "#{listener}.process/1 raised an error!\n#{inspect(error)}"
    Logger.log(@logging_level, msg)
  end
end
