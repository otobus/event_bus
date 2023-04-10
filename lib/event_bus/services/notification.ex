defmodule EventBus.Service.Notification do
  @moduledoc false

  require Logger

  alias EventBus.Manager.Observation, as: ObservationManager
  alias EventBus.Manager.Store, as: StoreManager
  alias EventBus.Manager.Subscription, as: SubscriptionManager
  alias EventBus.Model.Event

  @typep event :: EventBus.event()
  @typep event_shadow :: EventBus.event_shadow()
  @typep subscriber :: EventBus.subscriber()
  @typep subscribers :: EventBus.subscribers()
  @typep topic :: EventBus.topic()

  @doc false
  @spec notify(event()) :: :ok
  def notify(%Event{id: id, topic: topic} = event) do
    subscribers = SubscriptionManager.subscribers(topic)

    if subscribers == [] do
      {:error, warn_missing_topic_subscription(topic)}
    else
      :ok = StoreManager.create(event)
      :ok = ObservationManager.create({subscribers, {topic, id}})

      notify_subscribers(subscribers, {topic, id})
    end
  end

  @spec notify_subscribers(subscribers(), event_shadow()) :: :ok
  defp notify_subscribers(subscribers, event_shadow) do
    Enum.map(subscribers, fn subscriber ->
      res = notify_subscriber(subscriber, event_shadow)
      {subscriber, res}
    end)
  end

  @spec notify_subscriber(subscriber(), event_shadow()) :: no_return()
  defp notify_subscriber({subscriber, config}, {topic, id}) do
    subscriber.process({config, topic, id})
  rescue
    error ->
      log_error(subscriber, error, __STACKTRACE__)
      ObservationManager.mark_as_skipped({{subscriber, config}, {topic, id}})
      {subscriber, {:error, error}}
  end

  defp notify_subscriber(subscriber, {topic, id}) do
    subscriber.process({topic, id})
  rescue
    error ->
      log_error(subscriber, error, __STACKTRACE__)
      ObservationManager.mark_as_skipped({subscriber, {topic, id}})
      {subscriber, {:error, error}}
  end

  @spec registration_status(topic()) :: String.t()
  defp registration_status(topic) do
    if EventBus.topic_exist?(topic), do: "", else: " doesn't exist!"
  end

  @spec warn_missing_topic_subscription(topic()) :: no_return()
  defp warn_missing_topic_subscription(topic) do
    msg =
      "Topic(:#{topic}#{registration_status(topic)}) doesn't have subscribers"

    :ok = Logger.warn(msg)
    msg
  end

  @spec log_error(module(), any(), any()) :: no_return()
  defp log_error(subscriber, error, stacktrace) do
    msg = "#{subscriber}.process/1 raised an error!\n" <> Exception.format(:error, error, stacktrace)
    Logger.error(msg)
  end
end
