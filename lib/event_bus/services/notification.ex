defmodule EventBus.Service.Notification do
  @moduledoc false

  require Logger

  alias EventBus.Manager.Observation, as: ObservationManager
  alias EventBus.Manager.Store, as: StoreManager
  alias EventBus.Manager.Subscription, as: SubscriptionManager
  alias EventBus.Model.Event

  @typep event :: EventBus.event()
  @typep event_shadow :: EventBus.event_shadow()
  @typep listener :: EventBus.listener()
  @typep listener_list :: EventBus.listener_list()
  @typep topic :: EventBus.topic()

  @doc false
  @spec notify(event()) :: :ok
  def notify(%Event{id: id, topic: topic} = event) do
    listeners = SubscriptionManager.subscribers(topic)

    if listeners == [] do
      warn_missing_topic_subscription(topic)
    else
      :ok = StoreManager.create(event)
      :ok = ObservationManager.create({listeners, {topic, id}})

      notify_listeners(listeners, {topic, id})
    end

    :ok
  end

  @spec notify_listeners(listener_list(), event_shadow()) :: :ok
  defp notify_listeners(listeners, event_shadow) do
    Enum.each(listeners, fn listener ->
      notify_listener(listener, event_shadow)
    end)
    :ok
  end

  @spec notify_listener(listener(), event_shadow()) :: no_return()
  defp notify_listener({listener, config}, {topic, id}) do
    listener.process({config, topic, id})
  rescue
    error ->
      log_error(listener, error)
      ObservationManager.mark_as_skipped({{listener, config}, {topic, id}})
  end

  defp notify_listener(listener, {topic, id}) do
    listener.process({topic, id})
  rescue
    error ->
      log_error(listener, error)
      ObservationManager.mark_as_skipped({listener, {topic, id}})
  end

  @spec registration_status(topic()) :: String.t()
  defp registration_status(topic) do
    if EventBus.topic_exist?(topic), do: "", else: " doesn't exist!"
  end

  @spec warn_missing_topic_subscription(topic()) :: no_return()
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
