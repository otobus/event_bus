defmodule EventBus.Service.Subscription do
  @moduledoc false

  alias EventBus.Manager.Topic
  alias EventBus.Util.Regex, as: RegexUtil

  @app :event_bus
  @namespace :subscriptions

  @spec subscribed?(tuple()) :: boolean()
  def subscribed?(subscriber) do
    Enum.member?(subscribers(), subscriber)
  end

  @doc false
  @spec subscribe(tuple()) :: no_return()
  def subscribe({listener, topics}) do
    {listeners, topic_map} = load_state()
    listeners = add_or_update_listener(listeners, {listener, topics})

    topic_map =
      topic_map
      |> add_listener_to_topic_map({listener, topics})
      |> Enum.into(%{})

    save_state({listeners, topic_map})
  end

  @doc false
  @spec unsubscribe(tuple() | module()) :: no_return()
  def unsubscribe(listener) do
    {listeners, topic_map} = load_state()
    listeners = List.keydelete(listeners, listener, 0)

    topic_map =
      topic_map
      |> remove_listener_from_topic_map(listener)
      |> Enum.into(%{})

    save_state({listeners, topic_map})
  end

  @doc false
  @spec register_topic(String.t() | atom()) :: no_return()
  def register_topic(topic) do
    {listeners, topic_map} = load_state()
    topic_listeners = topic_listeners(listeners, topic)

    save_state({listeners, Map.put(topic_map, topic, topic_listeners)})
  end

  @doc false
  @spec unregister_topic(String.t() | atom()) :: no_return()
  def unregister_topic(topic) do
    {listeners, topic_map} = load_state()
    save_state({listeners, Map.drop(topic_map, [topic])})
  end

  @doc false
  def subscribers do
    {listeners, _topic_map} = load_state()
    listeners
  end

  def subscribers(topic) do
    {_listeners, topic_map} = load_state()
    topic_map[topic] || []
  end

  defp topic_listeners(listeners, topic) do
    Enum.reduce(listeners, [], fn {listener, topics}, acc ->
      if RegexUtil.superset?(topics, topic), do: [listener | acc], else: acc
    end)
  end

  defp remove_listener_from_topic_map(topic_map, listener) do
    Enum.map(topic_map, fn {topic, topic_listeners} ->
      topic_listeners = List.delete(topic_listeners, listener)
      {topic, topic_listeners}
    end)
  end

  defp add_listener_to_topic_map(topic_map, {listener, topics}) do
    Enum.map(topic_map, fn {topic, topic_listeners} ->
      topic_listeners = List.delete(topic_listeners, listener)

      if RegexUtil.superset?(topics, topic) do
        {topic, [listener | topic_listeners]}
      else
        {topic, topic_listeners}
      end
    end)
  end

  defp add_or_update_listener(listeners, {listener, topics}) do
    if List.keymember?(listeners, listener, 0) do
      List.keyreplace(listeners, listener, 0, {listener, topics})
    else
      [{listener, topics} | listeners]
    end
  end

  defp save_state(state) do
    Application.put_env(@app, @namespace, state, persistent: true)
  end

  defp load_state do
    Application.get_env(@app, @namespace, {[], init_topic_map()})
  end

  defp init_topic_map do
    topics = Topic.all()

    topics
    |> Enum.map(fn topic -> {topic, []} end)
    |> Enum.into(%{})
  end
end
