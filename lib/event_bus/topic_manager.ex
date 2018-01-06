defmodule EventBus.TopicManager do
  @moduledoc """
  Topic manager
  """

  use GenServer
  alias EventBus.Config
  alias EventBus.EventStore
  alias EventBus.EventWatcher
  alias EventBus.SubscriptionManager

  @app :event_bus
  @namespace :topics

  @doc false
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_) do
    {:ok, nil}
  end

  @doc """
  Register all topics from config
  """
  def register_from_config do
    Enum.each(Config.topics(), fn topic ->
      EventStore.register_topic(topic)
      EventWatcher.register_topic(topic)
      SubscriptionManager.register_topic(topic)
    end)
  end

  @doc """
  Register a topic
  """
  def register(topic),
    do: GenServer.cast(__MODULE__, {:register, topic})

  def unregister(topic),
    do: GenServer.cast(__MODULE__, {:unregister, topic})

  def handle_cast({:register, topic}, state) do
    create(topic)
    {:noreply, state}
  end
  def handle_cast({:unregister, topic}, state) do
    delete(topic)
    {:noreply, state}
  end

  defp create(topic) do
    topic  = :"#{topic}"
    topics = Config.topics()
    unless Enum.member?(topics, topic) do
      Application.put_env(@app, @namespace, [topic | topics], persistent: true)
      EventStore.register_topic(topic)
      EventWatcher.register_topic(topic)
      SubscriptionManager.register_topic(topic)
    end
  end

  defp delete(topic) do
    topic  = :"#{topic}"
    topics = Config.topics()
    if Enum.member?(topics, topic) do
      EventStore.unregister_topic(topic)
      EventWatcher.unregister_topic(topic)
      SubscriptionManager.unregister_topic(topic)
      topics = List.delete(topics, topic)
      Application.put_env(@app, @namespace, topics, persistent: true)
    end
  end
end
