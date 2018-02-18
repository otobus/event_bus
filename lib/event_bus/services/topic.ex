defmodule EventBus.Service.Topic do
  @moduledoc false

  alias EventBus.Store
  alias EventBus.Watcher
  alias EventBus.Subscription

  @app :event_bus
  @namespace :topics
  @modules [Store, Watcher, Subscription]

  @doc false
  @spec all() :: list(atom())
  def all,
    do: Application.get_env(:event_bus, :topics, [])

  @doc false
  @spec exist?(String.t() | atom()) :: boolean()
  def exist?(topic),
    do: Enum.member?(all(), :"#{topic}")

  @doc false
  @spec register_from_config() :: no_return()
  def register_from_config do
    for topic <- all() do
      Enum.each(@modules, fn mod -> mod.register_topic(topic) end)
    end
  end

  @doc false
  @spec register(String.t() | atom()) :: no_return()
  def register(topic) do
    topic = :"#{topic}"
    topics = all()

    unless Enum.member?(topics, topic) do
      Application.put_env(@app, @namespace, [topic | topics], persistent: true)
      Enum.each(@modules, fn mod -> mod.register_topic(topic) end)
    end
  end

  @doc false
  @spec unregister(String.t() | atom()) :: no_return()
  def unregister(topic) do
    topic = :"#{topic}"
    topics = all()

    if Enum.member?(topics, topic) do
      Enum.each(@modules, fn mod -> mod.unregister_topic(topic) end)
      topics = List.delete(topics, topic)
      Application.put_env(@app, @namespace, topics, persistent: true)
    end
  end
end
