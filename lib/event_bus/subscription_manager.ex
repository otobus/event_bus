defmodule EventBus.SubscriptionManager do
  @moduledoc """
  Subscription Manager
  """

  use GenServer
  alias EventBus.Config

  @doc false
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  def init(_),
    do: {:ok, load_state()}

  @doc false
  @spec subscribe({tuple() | module(), list()}) :: no_return()
  def subscribe({listener, topics}),
    do: GenServer.cast(__MODULE__, {:subscribe, {listener, topics}})

  @doc false
  @spec unsubscribe({tuple() | module()}) :: no_return()
  def unsubscribe(listener),
    do: GenServer.cast(__MODULE__, {:unsubscribe, listener})

  @doc false
  @spec register_topic(atom()) :: no_return()
  def register_topic(topic),
    do: GenServer.cast(__MODULE__, {:register_topic, topic})

  @doc false
  @spec unregister_topic(atom()) :: no_return()
  def unregister_topic(topic),
    do: GenServer.cast(__MODULE__, {:unregister_topic, topic})

  @doc false
  @spec subscribers() :: list(tuple() | module())
  def subscribers,
    do: GenServer.call(__MODULE__, {:subscribers})

  @doc false
  @spec subscribers(atom()) :: list(tuple() | module())
  def subscribers(topic),
    do: GenServer.call(__MODULE__, {:subscribers, topic})

  @doc false
  def handle_cast({:subscribe, {listener, topics}}, {listeners, topic_map}) do
    listeners = add_or_update_listener(listeners, {listener, topics})
    topic_map =
      topic_map
      |> add_listener_to_topic_map({listener, topics})
      |> Enum.into(%{})

    save_state({listeners, topic_map})
    {:noreply, {listeners, topic_map}}
  end

  @doc false
  def handle_cast({:unsubscribe, listener}, {listeners, topic_map}) do
    listeners = List.keydelete(listeners, listener, 0)
    topic_map =
      topic_map
      |> remove_listener_from_topic_map(listener)
      |> Enum.into(%{})

    save_state({listeners, topic_map})
    {:noreply, {listeners, topic_map}}
  end

  @doc false
  def handle_cast({:register_topic, topic}, {listeners, topic_map}) do
    topic_subscribers =
      Enum.reduce(listeners, [], fn({listener, topics}, acc) ->
        if superset?(topics, topic), do: [listener | acc], else: acc
      end)

    {:noreply, {listeners, Map.put(topic_map, topic, topic_subscribers)}}
  end

  @doc false
  def handle_cast({:unregister_topic, topic}, {listeners, topic_map}),
    do: {:noreply, {listeners, Map.drop(topic_map, [topic])}}

  @doc false
  def handle_call({:subscribers}, _from, {listeners, _} = state),
    do: {:reply, listeners, state}
  def handle_call({:subscribers, topic}, _from, {_, topic_map} = state),
    do: {:reply, topic_map[topic] || [], state}

  defp superset?(topics, topic) do
    topics_pattern =
      topics
      |> Enum.map(fn t -> "^(#{t})" end)
      |> Enum.join("|")

    case Regex.compile(topics_pattern) do
      {:ok, pattern} -> Regex.match?(pattern, "#{topic}")
      _ -> false
    end
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
      if superset?(topics, topic) do
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

  defp save_state(state),
    do: Application.put_env(:event_bus, :subscriptions, state, persistent: true)

  defp load_state,
    do: Application.get_env(:event_bus, :subscriptions, {[], init_topic_map()})

  defp init_topic_map do
    topics = Config.topics()
    topics
    |> Enum.map(fn topic -> {topic, []} end)
    |> Enum.into(%{})
  end
end
