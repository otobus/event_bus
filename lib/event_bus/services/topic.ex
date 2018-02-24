defmodule EventBus.Service.Topic do
  @moduledoc false

  alias EventBus.Manager.{Observation, Store, Subscription}

  @app :event_bus
  @namespace :topics
  @modules [Store, Subscription, Observation]

  @doc false
  @spec all() :: list(atom())
  def all do
    Application.get_env(:event_bus, :topics, [])
  end

  @doc false
  @spec exist?(atom()) :: boolean()
  def exist?(topic) do
    Enum.member?(all(), topic)
  end

  @doc false
  @spec register_from_config() :: no_return()
  def register_from_config do
    for topic <- all() do
      Enum.each(@modules, fn mod -> mod.register_topic(topic) end)
    end
  end

  @doc false
  @spec register(atom()) :: no_return()
  def register(topic) do
    unless exist?(topic) do
      Application.put_env(@app, @namespace, [topic | all()], persistent: true)
      Enum.each(@modules, fn mod -> mod.register_topic(topic) end)
    end
  end

  @doc false
  @spec unregister(atom()) :: no_return()
  def unregister(topic) do
    if exist?(topic) do
      Enum.each(@modules, fn mod -> mod.unregister_topic(topic) end)
      topics = List.delete(all(), topic)
      Application.put_env(@app, @namespace, topics, persistent: true)
    end
  end
end
