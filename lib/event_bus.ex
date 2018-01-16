defmodule EventBus do
  @moduledoc """
  Simple event bus implementation.
  """

  alias EventBus.{Notifier, Store, Watcher, Subscription,
    Topic, Model.Event}

  @doc """
  Send event to all listeners.

  ## Examples

      event = %Event{id: 1, topic: :webhook_received,
        data: %{"message" => "Hi all!"}}
      EventBus.notify(event)
      :ok

  """
  @spec notify(Event.t) :: :ok
  defdelegate notify(event),
    to: Notifier, as: :notify

  @doc """
  Check if topic registered.

  ## Examples

      EventBus.topic_exist?(:demo_topic)
      true

  """
  @spec topic_exist?(String.t | atom()) :: boolean()
  defdelegate topic_exist?(topic),
    to: Topic, as: :exist?

  @doc """
  List all registered topics.

  ## Examples

      EventBus.topics()
      [:metrics_summed]
  """
  @spec topics() :: list(atom())
  defdelegate topics,
    to: Topic, as: :all

  @doc """
  Register a topic

  ## Examples

      EventBus.register_topic(:demo_topic)
      :ok

  """
  @spec register_topic(String.t | atom()) :: boolean()
  defdelegate register_topic(topic),
    to: Topic, as: :register

  @doc """
  Unregister a topic

  ## Examples

      EventBus.unregister_topic(:demo_topic)
      :ok

  """
  @spec unregister_topic(String.t | atom()) :: boolean()
  defdelegate unregister_topic(topic),
    to: Topic, as: :unregister

  @doc """
  Subscribe to the bus.

  ## Examples

      EventBus.subscribe({MyEventListener, [".*"]})
      :ok

      # For configurable listeners you can pass tuple of listener and config
      my_config = %{}
      EventBus.subscribe({{OtherListener, my_config}, [".*"]})
      :ok

  """
  @spec subscribe(tuple()) :: :ok
  defdelegate subscribe(listener_with_topics),
    to: Subscription, as: :subscribe

  @doc """
  Unsubscribe from the bus.

  ## Examples

      EventBus.unsubscribe(MyEventListener)
      :ok

      # For configurable listeners you must pass tuple of listener and config
      my_config = %{}
      EventBus.unsubscribe({{OtherListener, my_config}})
      :ok

  """
  @spec unsubscribe({tuple() | module()}) :: :ok
  defdelegate unsubscribe(listener),
    to: Subscription, as: :unsubscribe

  @doc """
  List the subscribers.

  ## Examples

      EventBus.subscribers()
      [MyEventListener]

      # One usual and one configured listener with its config
      EventBus.subscribers()
      [MyEventListener, {OtherListener, %{}}]

  """
  @spec subscribers() :: list(any())
  defdelegate subscribers,
    to: Subscription, as: :subscribers

  @doc """
  List the subscribers to the with given topic.

  ## Examples

      EventBus.subscribers(:metrics_received)
      [MyEventListener]

      # One usual and one configured listener with its config
      EventBus.subscribers(:metrics_received)
      [MyEventListener, {OtherListener, %{}}]

  """
  @spec subscribers(atom() | String.t) :: list(any())
  defdelegate subscribers(topic),
    to: Subscription, as: :subscribers

  @doc """
  Fetch event data

  ## Examples

      EventBus.fetch_event({:hello_received, "123"})

  """
  @spec fetch_event({atom(), String.t | integer()}) :: Event.t
  defdelegate fetch_event(event_shadow),
    to: Store, as: :fetch

  @doc """
  Send the event processing completed to the watcher

  ## Examples

      EventBus.mark_as_completed({MyEventListener, :hello_received, "123"})

      # For configurable listeners you must pass tuple of listener and config
      my_config = %{}
      listener = {OtherListener, my_config}
      EventBus.mark_as_completed({listener, :hello_received, "124"})
      :ok

  """
  @spec mark_as_completed({tuple() | module(), atom(), String.t | integer()})
    :: no_return()
  defdelegate mark_as_completed(listener_with_event_shadow),
    to: Watcher, as: :mark_as_completed

  @doc """
  Send the event processing skipped to the watcher

  ## Examples

      EventBus.mark_as_skipped({MyEventListener, :unmatched_occurred, "124"})

      # For configurable listeners you must pass tuple of listener and config
      my_config = %{}
      listener = {OtherListener, my_config}
      EventBus.mark_as_skipped({listener, :unmatched_occurred, "124"})
      :ok

  """
  @spec mark_as_skipped({tuple() | module(), atom(), String.t | integer()})
    :: no_return()
  defdelegate mark_as_skipped(listener_with_event_shadow),
    to: Watcher, as: :mark_as_skipped
end
