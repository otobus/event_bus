defmodule EventBus.Service.Notification do
  @moduledoc false

  require Logger

  alias EventBus.Manager.Observation, as: ObservationManager
  alias EventBus.Manager.Store, as: StoreManager
  alias EventBus.Manager.Subscription, as: SubscriptionManager
  alias EventBus.Model.Event

  @doc false
  @spec notify(Event.t()) :: no_return()
  def notify(%Event{id: id, topic: topic} = event) do
    listeners = SubscriptionManager.subscribers(topic)

    if listeners == [] do
      warn_missing_topic_subscription(topic)
    else
      :ok = StoreManager.create(event)
      :ok = ObservationManager.create({listeners, {topic, id}})

      notify_listeners(listeners, {topic, id})
    end
  end

  @spec notify_listeners(list(), tuple()) :: no_return()
  defp notify_listeners(listeners, event_shadow) do
    for listener <- listeners, do: notify_listener(listener, event_shadow)
  end

  @spec notify_listener(tuple(), tuple()) :: no_return()
  defp notify_listener({listener, config}, {topic, id}) do
    listener.process({config, topic, id})
  rescue
    error ->
      log_error(listener, error)
      ObservationManager.mark_as_skipped({{listener, config}, {topic, id}})
  end

  @spec notify_listener(module(), tuple()) :: no_return()
  defp notify_listener(listener, {topic, id}) do
    listener.process({topic, id})
  rescue
    error ->
      log_error(listener, error)
      ObservationManager.mark_as_skipped({listener, {topic, id}})
  end

  @spec registration_status(atom()) :: String.t()
  defp registration_status(topic) do
    if EventBus.topic_exist?(topic), do: "", else: " doesn't exist!"
  end

  @spec warn_missing_topic_subscription(atom()) :: no_return()
  defp warn_missing_topic_subscription(topic) do
    msg =
      "Topic(:#{topic}#{registration_status(topic)}) doesn't have subscribers"

    Logger.warn(msg)
  end

  @spec log_error(module(), any()) :: no_return()
  defp log_error(listener, error) do
    msg = "#{listener}.process/1 raised an error!\n#{inspect(error)}"
    Logger.info(msg)
  end
end
