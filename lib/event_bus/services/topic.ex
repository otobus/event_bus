defmodule EventBus.Service.Topic do
  @moduledoc false

  alias EventBus.Manager.Observation, as: ObservationManager
  alias EventBus.Manager.Store, as: StoreManager
  alias EventBus.Manager.Subscription, as: SubscriptionManager

  @typep topic :: EventBus.topic()
  @typep topics :: EventBus.topics()

  @app :event_bus
  @namespace :topics
  @modules [StoreManager, SubscriptionManager, ObservationManager]

  @doc false
  @spec all() :: topics()
  def all do
    Application.get_env(:event_bus, :topics, [])
  end

  @doc false
  @spec exist?(topic()) :: boolean()
  def exist?(topic) do
    Enum.member?(all(), topic)
  end

  @doc false
  @spec register_from_config() :: :ok
  def register_from_config do
    Enum.each(all(), fn topic ->
      Enum.each(@modules, fn mod -> mod.register_topic(topic) end)
    end)

    :ok
  end

  @doc false
  @spec register(topic()) :: :ok
  def register(topic) do
    unless exist?(topic) do
      Application.put_env(@app, @namespace, [topic | all()], persistent: true)
      Enum.each(@modules, fn mod -> mod.register_topic(topic) end)
    end

    :ok
  end

  @doc false
  @spec unregister(topic()) :: :ok
  def unregister(topic) do
    if exist?(topic) do
      Enum.each(@modules, fn mod -> mod.unregister_topic(topic) end)
      topics = List.delete(all(), topic)
      Application.put_env(@app, @namespace, topics, persistent: true)
    end

    :ok
  end
end
