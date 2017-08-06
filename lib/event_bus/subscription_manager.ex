defmodule EventBus.SubscriptionManager do
  @moduledoc """
  Subscription Manager
  """

  use GenServer
  alias EventBus.Config

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, load_state()}
  end

  @doc false
  def subscribe({listener, topics}) do
    GenServer.cast(__MODULE__, {:subscribe, {listener, topics}})
  end

  @doc false
  def unsubscribe(listener) do
    GenServer.cast(__MODULE__, {:unsubscribe, listener})
  end

  @doc false
  def subscribers do
    GenServer.call(__MODULE__, {:subscribers})
  end

  @doc false
  def subscribers(event_name) do
    GenServer.call(__MODULE__, {:subscribers, event_name})
  end

  @doc false
  def handle_cast({:subscribe, {listener, topics}}, {listeners, event_map}) do
    listeners = add_or_update_listener(listeners, {listener, topics})
    event_map =
      event_map
      |> add_listener_to_event_map({listener, topics})
      |> Enum.into(%{})

    save_state({listeners, event_map})
    {:noreply, {listeners, event_map}}
  end

  @doc false
  def handle_cast({:unsubscribe, listener}, {listeners, event_map}) do
    listeners = List.keydelete(listeners, listener, 0)
    event_map =
      event_map
      |> remove_listener_from_event_map(listener)
      |> Enum.into(%{})

    save_state({listeners, event_map})
    {:noreply, {listeners, event_map}}
  end

  @doc false
  def handle_call({:subscribers}, _from, {listeners, _} = state) do
    {:reply, listeners, state}
  end
  def handle_call({:subscribers, event_name}, _from, {_, event_map} = state) do
    {:reply, event_map[event_name] || [], state}
  end

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

  defp remove_listener_from_event_map(event_map, listener) do
    Enum.map(event_map, fn {topic, topic_listeners} ->
      topic_listeners = List.delete(topic_listeners, listener)
      {topic, topic_listeners}
    end)
  end

  defp add_listener_to_event_map(event_map, {listener, topics}) do
    Enum.map(event_map, fn {topic, topic_listeners} ->
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

  defp save_state(state) do
    Application.put_env(:event_bus, :subscriptions, state)
  end

  defp load_state do
    events = Config.events()
    event_map =
      events
      |> Enum.map(fn event_name -> {event_name, []} end)
      |> Enum.into(%{})

    Application.get_env(:event_bus, :subscriptions, {[], event_map})
  end
end
