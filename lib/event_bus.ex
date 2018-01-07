defmodule EventBus do
  @moduledoc """
  Simple event bus implementation.
  """

  alias EventBus.EventManager
  alias EventBus.SubscriptionManager
  alias EventBus.TopicManager
  alias EventBus.EventStore
  alias EventBus.EventWatcher
  alias EventBus.Model.Event

  @doc """
  Send event to all listeners.

  ## Examples

      event = %Event{id: 1, topic: :webhook_received,
        data: %{"message" => "Hi all!"}}
      EventBus.notify(event)
      :ok

  """
  @spec notify(Event.t) :: :ok
  def notify(%Event{topic: topic} = event) do
    EventManager.notify(subscribers(topic), event)
  end

  @doc """
  Check if topic registered.

  ## Examples

      EventBus.topic_exist?(:demo_topic)
      true

  """
  @spec topic_exist?(String.t | atom()) :: boolean()
  def topic_exist?(topic) do
    event_topics = Application.get_env(:event_bus, :topics, [])
    Enum.any?(event_topics,
      fn event_topic -> event_topic == String.to_atom("#{topic}") end)
  end

  @doc """
  Register a topic

  ## Examples

      EventBus.register_topic(:demo_topic)
      :ok

  """
  @spec register_topic(String.t | atom()) :: boolean()
  defdelegate register_topic(topic),
    to: TopicManager, as: :register

  @doc """
  Unregister a topic

  ## Examples

      EventBus.unregister_topic(:demo_topic)
      :ok

  """
  @spec register_topic(String.t | atom()) :: boolean()
  defdelegate unregister_topic(topic),
    to: TopicManager, as: :unregister

  @doc """
  Subscribe to the bus.

  ## Examples

      EventBus.subscribe({MyEventListener, [".*"]})
      :ok

      # For configurable listeners you can pass tuple of processor and config
      my_config = %{}
      EventBus.subscribe({{OtherListener, my_config}, [".*"]})
      :ok

  """
  @spec subscribe(tuple()) :: :ok
  defdelegate subscribe(subscriber),
    to: SubscriptionManager, as: :subscribe

  @doc """
  Unsubscribe from the bus.

  ## Examples

      EventBus.unsubscribe(MyEventListener)
      :ok

      # For configurable listeners you must pass tuple of processor and config
      my_config = %{}
      EventBus.unsubscribe({{OtherListener, my_config}, [".*"]})
      :ok

  """
  @spec unsubscribe(any()) :: :ok
  defdelegate unsubscribe(listener),
    to: SubscriptionManager, as: :unsubscribe

  @doc """
  List the subscribers to the bus.

  ## Examples

      EventBus.subscribers()
      [MyEventListener]

      # One usual and one configured listener with its config
      EventBus.subscribers()
      [MyEventListener, {OtherListener, %{}}]

  """
  @spec subscribers() :: list(any())
  defdelegate subscribers,
    to: SubscriptionManager, as: :subscribers

  @doc """
  List the subscribers to the bus with given event name.

  ## Examples

      EventBus.subscribers(:metrics_received)
      [MyEventListener]

      # One usual and one configured listener with its config
      EventBus.subscribers(:metrics_received)
      [MyEventListener, {OtherListener, %{}}]

  """
  @spec subscribers(atom() | String.t) :: list(any())
  defdelegate subscribers(event_name),
    to: SubscriptionManager, as: :subscribers

  @doc """
  Fetch event data

  ## Examples

      EventBus.fetch_event({:hello_received, "123"})

  """
  @spec fetch_event(tuple()) :: Event.t
  defdelegate fetch_event(event_shadow),
    to: EventStore, as: :fetch

  @doc """
  Send the event processing completed to the watcher

  ## Examples

      EventBus.mark_as_completed({MyEventListener, :hello_received, "123"})

  """
  @spec mark_as_completed(tuple()) :: no_return()
  defdelegate mark_as_completed(event_with_listener),
    to: EventWatcher, as: :mark_as_completed

  @doc """
  Send the event processing skipped to the watcher

  ## Examples

      EventBus.mark_as_skipped({MyEventListener, :unmatched_occurred, "124"})

      # For configurable listeners you must pass tuple of processor and config
      my_config = %{}
      listener = {OtherListener, my_config}
      EventBus.mark_as_skipped({listener, :unmatched_occurred, "124"})
      :ok

  """
  @spec mark_as_skipped(tuple()) :: no_return()
  defdelegate mark_as_skipped(event_with_listener),
    to: EventWatcher, as: :mark_as_skipped
end
