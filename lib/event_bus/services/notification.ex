defmodule EventBus.Service.Notification do
  @moduledoc false

  require Logger

  alias EventBus.Manager.Observation, as: ObservationManager
  alias EventBus.Manager.Store, as: StoreManager
  alias EventBus.Manager.Subscription, as: SubscriptionManager
  alias EventBus.Model.Event

  @logging_level :info

  @doc false
  @spec notify(Event.t()) :: no_return()
  def notify(%Event{id: id, topic: topic} = event) do
    listeners = SubscriptionManager.subscribers(topic)

    if listeners == [] do
      Logger.log(
        @logging_level,
        "Topic(:#{topic}#{registration_status(topic)}) doesn't have subscribers"
      )
    else
      :ok = StoreManager.create(event)
      :ok = ObservationManager.create({listeners, topic, id})

      notify_listeners(listeners, {topic, id})
    end
  end

  @spec notify_listeners(list(), tuple()) :: no_return()
  defp notify_listeners(listeners, event_shadow) do
    for listener <- listeners, do: notify_listener(listener, event_shadow)
  end

  @spec notify_listener(tuple(), tuple()) :: no_return()
  @spec notify_listener(module(), tuple()) :: no_return()
  defp notify_listener({listener, config}, {topic, id}) do
    listener.process({config, topic, id})
  rescue
    error ->
      log(listener, error)
      ObservationManager.mark_as_skipped({{listener, config}, topic, id})
  end

  defp notify_listener(listener, {topic, id}) do
    listener.process({topic, id})
  rescue
    error ->
      log(listener, error)
      ObservationManager.mark_as_skipped({listener, topic, id})
  end

  @spec registration_status(atom()) :: String.t()
  defp registration_status(topic) do
    if EventBus.topic_exist?(topic), do: "", else: " doesn't exist!"
  end

  @spec log(module(), any()) :: no_return()
  defp log(listener, error) do
    msg = "#{listener}.process/1 raised an error!\n#{inspect(error)}"
    Logger.log(@logging_level, msg)
  end
end
