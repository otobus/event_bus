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
  @modules [EventStore, EventWatcher, SubscriptionManager]

  @doc false
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  def init(_),
    do: {:ok, nil}

  @doc """
  Register all topics from config
  """
  @spec register_from_config() :: no_return()
  def register_from_config do
    topics = Config.topics()
    for topic <- topics do
      Enum.each(@modules, fn mod -> mod.register_topic(topic) end)
    end
  end

  @doc """
  Register a topic
  """
  @spec register(String.t | atom()) :: no_return()
  def register(topic),
    do: GenServer.cast(__MODULE__, {:register, topic})

  @doc """
  Unregister a topic
  """
  @spec unregister(String.t | atom()) :: no_return()
  def unregister(topic),
    do: GenServer.cast(__MODULE__, {:unregister, topic})

  @doc false
  @spec handle_cast({:register, String.t | atom()}, nil) :: no_return()
  def handle_cast({:register, topic}, state) do
    create(topic)
    {:noreply, state}
  end
  @spec handle_cast({:unregister, String.t | atom()}, nil) :: no_return()
  def handle_cast({:unregister, topic}, state) do
    delete(topic)
    {:noreply, state}
  end

  @spec create(String.t | atom()) :: no_return()
  defp create(topic) do
    topic  = :"#{topic}"
    topics = Config.topics()
    unless Enum.member?(topics, topic) do
      Application.put_env(@app, @namespace, [topic | topics], persistent: true)
      Enum.each(@modules, fn mod -> mod.register_topic(topic) end)
    end
  end

  @spec delete(String.t | atom()) :: no_return()
  defp delete(topic) do
    topic  = :"#{topic}"
    topics = Config.topics()
    if Enum.member?(topics, topic) do
      Enum.each(@modules, fn mod -> mod.unregister_topic(topic) end)
      topics = List.delete(topics, topic)
      Application.put_env(@app, @namespace, topics, persistent: true)
    end
  end
end
