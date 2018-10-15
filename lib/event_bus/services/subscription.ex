defmodule EventBus.Service.Subscription do
  @moduledoc false

  alias EventBus.Manager.Topic, as: TopicManager
  alias EventBus.Util.Regex, as: RegexUtil

  @app :event_bus
  @namespace :subscriptions

  @typep subscriber :: EventBus.subscriber()
  @typep subscribers :: EventBus.subscribers()
  @typep subscriber_with_topic_patterns :: EventBus.subscriber_with_topic_patterns()
  @typep topic :: EventBus.topic()

  @spec subscribed?(subscriber_with_topic_patterns()) :: boolean()
  def subscribed?(subscriber) do
    Enum.member?(subscribers(), subscriber)
  end

  @doc false
  @spec subscribe(subscriber_with_topic_patterns()) :: :ok
  def subscribe({subscriber, topics}) do
    {subscribers, topic_map} = load_state()
    subscribers = add_or_update_subscriber(subscribers, {subscriber, topics})

    topic_map =
      topic_map
      |> add_subscriber_to_topic_map({subscriber, topics})
      |> Enum.into(%{})

    save_state({subscribers, topic_map})
  end

  @doc false
  @spec unsubscribe(subscriber()) :: :ok
  def unsubscribe(subscriber) do
    {subscribers, topic_map} = load_state()
    subscribers = List.keydelete(subscribers, subscriber, 0)

    topic_map =
      topic_map
      |> remove_subscriber_from_topic_map(subscriber)
      |> Enum.into(%{})

    save_state({subscribers, topic_map})
  end

  @doc false
  @spec register_topic(topic()) :: :ok
  def register_topic(topic) do
    {subscribers, topic_map} = load_state()
    topic_subscribers = topic_subscribers(subscribers, topic)

    save_state({subscribers, Map.put(topic_map, topic, topic_subscribers)})
  end

  @doc false
  @spec unregister_topic(topic()) :: :ok
  def unregister_topic(topic) do
    {subscribers, topic_map} = load_state()
    save_state({subscribers, Map.drop(topic_map, [topic])})
  end

  @doc false
  @spec subscribers() :: subscribers()
  def subscribers do
    {subscribers, _topic_map} = load_state()
    subscribers
  end

  @spec subscribers(topic()) :: subscribers()
  def subscribers(topic) do
    {_subscribers, topic_map} = load_state()
    topic_map[topic] || []
  end

  defp topic_subscribers(subscribers, topic) do
    Enum.reduce(subscribers, [], fn {subscriber, topics}, acc ->
      if RegexUtil.superset?(topics, topic), do: [subscriber | acc], else: acc
    end)
  end

  defp remove_subscriber_from_topic_map(topic_map, subscriber) do
    Enum.map(topic_map, fn {topic, topic_subscribers} ->
      topic_subscribers = List.delete(topic_subscribers, subscriber)
      {topic, topic_subscribers}
    end)
  end

  defp add_subscriber_to_topic_map(topic_map, {subscriber, topics}) do
    Enum.map(topic_map, fn {topic, topic_subscribers} ->
      topic_subscribers = List.delete(topic_subscribers, subscriber)

      if RegexUtil.superset?(topics, topic) do
        {topic, [subscriber | topic_subscribers]}
      else
        {topic, topic_subscribers}
      end
    end)
  end

  defp add_or_update_subscriber(subscribers, {subscriber, topics}) do
    if List.keymember?(subscribers, subscriber, 0) do
      List.keyreplace(subscribers, subscriber, 0, {subscriber, topics})
    else
      [{subscriber, topics} | subscribers]
    end
  end

  defp save_state(state) do
    Application.put_env(@app, @namespace, state, persistent: true)
  end

  defp load_state do
    Application.get_env(@app, @namespace, {[], init_topic_map()})
  end

  defp init_topic_map do
    Enum.into(TopicManager.all(), %{}, fn topic -> {topic, []} end)
  end
end
