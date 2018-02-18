defmodule EventBus do
  @moduledoc """
  Traceable, extendable and minimalist event bus implementation for Elixir with
  built-in event store and event watcher based on ETS
  """

  use EventBus.EventSource
  alias EventBus.{Notifier, Store, Watcher, Subscription, Topic}

  @app :event_bus
  @source "eb"
  @sys_topic :eb_action_called
  @observables Application.get_env(@app, :observables, [])

  defmacrop is_observable(action) do
    quote do
      unquote(action) in unquote(@observables)
    end
  end

  defmacrop is_observable(action, topic) do
    quote do
      unquote(action) in unquote(@observables) and
        unquote(topic) != unquote(@sys_topic)
    end
  end

  @doc """
  Send event to all subscribers(listeners).

  ## Examples

      event = %Event{id: 1, topic: :webhook_received,
        data: %{"message" => "Hi all!"}}
      EventBus.notify(event)
      :ok

  """
  @spec notify(Event.t()) :: :ok
  def notify(%Event{id: id, topic: topic} = event)
      when is_observable(:notify, topic) do
    EventSource.notify sys_params() do
      Notifier.notify(event)
      %{action: :notify, id: id, subscribers: subscribers(topic), topic: topic}
    end

    :ok
  end

  defdelegate notify(topic),
    to: Notifier,
    as: :notify

  @doc """
  Check if topic registered.

  ## Examples

      EventBus.topic_exist?(:demo_topic)
      true

  """
  @spec topic_exist?(String.t() | atom()) :: boolean()
  defdelegate topic_exist?(topic),
    to: Topic,
    as: :exist?

  @doc """
  List all registered topics.

  ## Examples

      EventBus.topics()
      [:metrics_summed]
  """
  @spec topics() :: list(atom())
  defdelegate topics,
    to: Topic,
    as: :all

  @doc """
  Register a topic

  ## Examples

      EventBus.register_topic(:demo_topic)
      :ok

  """
  @spec register_topic(String.t() | atom()) :: :ok
  def register_topic(topic) when is_observable(:register_topic, topic) do
    unless topic_exist?(topic) do
      EventSource.notify sys_params() do
        Topic.register(topic)
        %{action: :register_topic, topic: topic}
      end
    end

    :ok
  end

  defdelegate register_topic(topic),
    to: Topic,
    as: :register

  @doc """
  Unregister a topic

  ## Examples

      EventBus.unregister_topic(:demo_topic)
      :ok

  """
  @spec unregister_topic(String.t() | atom()) :: :ok
  def unregister_topic(topic) when is_observable(:unregister_topic, topic) do
    if topic_exist?(topic) do
      EventSource.notify sys_params() do
        Topic.unregister(topic)
        %{action: :unregister_topic, topic: topic}
      end
    end

    :ok
  end

  defdelegate unregister_topic(topic),
    to: Topic,
    as: :unregister

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
  def subscribe({listener, topics}) when is_observable(:subscribe) do
    EventSource.notify sys_params() do
      Subscription.subscribe({listener, topics})
      %{action: :subscribe, listener: listener, topics: topics}
    end

    :ok
  end

  defdelegate subscribe(listener_with_topics),
    to: Subscription,
    as: :subscribe

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
  def unsubscribe(listener) when is_observable(:unsubscribe) do
    EventSource.notify sys_params() do
      Subscription.unsubscribe(listener)
      %{action: :unsubscribe, listener: listener}
    end

    :ok
  end

  defdelegate unsubscribe(listener),
    to: Subscription,
    as: :unsubscribe

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
    to: Subscription,
    as: :subscribers

  @doc """
  List the subscribers to the with given topic.

  ## Examples

      EventBus.subscribers(:metrics_received)
      [MyEventListener]

      # One usual and one configured listener with its config
      EventBus.subscribers(:metrics_received)
      [MyEventListener, {OtherListener, %{}}]

  """
  defdelegate subscribers(topic),
    to: Subscription,
    as: :subscribers

  @doc """
  Fetch event data

  ## Examples

      EventBus.fetch_event({:hello_received, "123"})

  """
  @spec fetch_event({atom(), String.t() | integer()}) :: Event.t()
  defdelegate fetch_event(event_shadow),
    to: Store,
    as: :fetch

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
  @spec mark_as_completed({tuple() | module(), atom(), String.t() | integer()})
        :: no_return()
  def mark_as_completed({listener, topic, id})
      when is_observable(:mark_as_completed, topic) do
    EventSource.notify sys_params() do
      Watcher.mark_as_completed({listener, topic, id})
      %{action: :mark_as_completed, id: id, listener: listener, topic: topic}
    end

    :ok
  end

  defdelegate mark_as_completed(listener_with_event_shadow),
    to: Watcher,
    as: :mark_as_completed

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
  @spec mark_as_skipped({tuple() | module(), atom(), String.t() | integer()})
        ::  no_return()
  def mark_as_skipped({listener, topic, id})
      when is_observable(:mark_as_skipped, topic) do
    EventSource.notify sys_params() do
      Watcher.mark_as_skipped({listener, topic, id})
      %{action: :mark_as_skipped, id: id, listener: listener, topic: topic}
    end

    :ok
  end

  defdelegate mark_as_skipped(listener_with_event_shadow),
    to: Watcher,
    as: :mark_as_skipped

  defp sys_params do
    id = Application.get_env(@app, :id_generator).()
    %{id: id, transaction_id: id, topic: @sys_topic, source: @source}
  end
end
