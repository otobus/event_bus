defmodule EventBus do
  @moduledoc """
  Traceable, extendable and minimalist event bus implementation for Elixir with
  built-in event store and event observation manager based on ETS
  """

  alias EventBus.Manager.{
    Notification,
    Observation,
    Store,
    Subscription,
    Topic
  }

  alias EventBus.Model.Event

  @typedoc "EventBus.Model.Event struct"
  @type event :: Event.t()

  @typedoc "Event id"
  @type event_id :: String.t() | integer()

  @typedoc "Tuple of topic name and event id"
  @type event_shadow :: {topic(), event_id()}

  @typedoc "Event listener/subscriber/consumer"
  @type listener :: {listener_without_config() | listener_with_config()}

  @typedoc "Listener configuration"
  @type listener_config :: any()

  @typedoc "List of event listeners/subscribers/consumers"
  @type listener_list :: list(listener())

  @typedoc "Event listener/subscriber/consumer with config"
  @type listener_with_config :: {module(), listener_config()}

  @typedoc "Tuple of listener and event reference"
  @type listener_with_event_ref ::
          listener_with_event_shadow() | listener_with_topic_and_event_id()

  @typedoc "Tuple of listener and event shadow"
  @type listener_with_event_shadow :: {listener(), event_shadow()}

  @typedoc "Tuple of listener, topic and event id"
  @type listener_with_topic_and_event_id :: {listener(), topic(), event_id()}

  @typedoc "Tuple of listener and list of topic patterns"
  @type listener_with_topic_patterns :: {listener(), topic_pattern_list()}

  @typedoc "Event listener/subscriber/consumer without config"
  @type listener_without_config :: module()

  @typedoc "Topic name"
  @type topic :: atom()

  @typedoc "List of topic names"
  @type topic_list :: list(topic())

  @typedoc "Regex pattern to match topic name"
  @type topic_pattern :: String.t()

  @typedoc "List of topic patterns"
  @type topic_pattern_list :: list(topic_pattern())

  @doc """
  Send event to all subscribers(listeners).

  ## Examples

      event = %Event{id: 1, topic: :webhook_received,
        data: %{"message" => "Hi all!"}}
      EventBus.notify(event)
      :ok

  """
  @spec notify(event()) :: :ok
  defdelegate notify(event),
    to: Notification,
    as: :notify

  @doc """
  Check if topic registered.

  ## Examples

      EventBus.topic_exist?(:demo_topic)
      true

  """
  @spec topic_exist?(topic()) :: boolean()
  defdelegate topic_exist?(topic),
    to: Topic,
    as: :exist?

  @doc """
  List all registered topics.

  ## Examples

      EventBus.topics()
      [:metrics_summed]
  """
  @spec topics() :: topic_list()
  defdelegate topics,
    to: Topic,
    as: :all

  @doc """
  Register a topic

  ## Examples

      EventBus.register_topic(:demo_topic)
      :ok

  """
  @spec register_topic(topic()) :: :ok
  defdelegate register_topic(topic),
    to: Topic,
    as: :register

  @doc """
  Unregister a topic

  ## Examples

      EventBus.unregister_topic(:demo_topic)
      :ok

  """
  @spec unregister_topic(topic()) :: :ok
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
  @spec subscribe(listener_with_topic_patterns()) :: :ok
  defdelegate subscribe(listener_with_topic_patterns),
    to: Subscription,
    as: :subscribe

  @doc """
  Unsubscribe from the bus.

  ## Examples

      EventBus.unsubscribe(MyEventListener)
      :ok

      # For configurable listeners you must pass tuple of listener and config
      my_config = %{}
      EventBus.unsubscribe({OtherListener, my_config})
      :ok

  """
  @spec unsubscribe(listener()) :: :ok
  defdelegate unsubscribe(listener),
    to: Subscription,
    as: :unsubscribe

  @doc """
  Is given listener subscribed to the bus for the given topic patterns?

  ## Examples

      EventBus.subscribe({MyEventListener, [".*"]})
      :ok

      EventBus.subscribed?({MyEventListener, [".*"]})
      true

      EventBus.subscribed?({MyEventListener, ["some_initialized"]})
      false

      EventBus.subscribed?({AnothEventListener, [".*"]})
      false

  """
  @spec subscribed?(listener_with_topic_patterns()) :: boolean()
  defdelegate subscribed?(listener_with_topic_patterns),
    to: Subscription,
    as: :subscribed?

  @doc """
  List the subscribers.

  ## Examples

      EventBus.subscribers()
      [MyEventListener]

      # One usual and one configured listener with its config
      EventBus.subscribers()
      [MyEventListener, {OtherListener, %{}}]

  """
  @spec subscribers() :: listener_list()
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
  Fetch event

  ## Examples

      EventBus.fetch_event({:hello_received, "123"})
      %EventBus.Model.Model{}

  """
  @spec fetch_event(event_shadow()) :: event()
  defdelegate fetch_event(event_shadow),
    to: Store,
    as: :fetch

  @doc """
  Fetch event data

  ## Examples

      EventBus.fetch_event_data({:hello_received, "123"})

  """
  @spec fetch_event_data(event_shadow()) :: any()
  defdelegate fetch_event_data(event_shadow),
    to: Store,
    as: :fetch_data

  @doc """
  Send the event processing completed to the Observation Manager

  ## Examples
      topic        = :hello_received
      event_id     = "124"
      event_shadow = {topic, event_id}

      # For regular listeners
      EventBus.mark_as_completed({MyEventListener, event_shadow})

      # For configurable listeners you must pass tuple of listener and config
      my_config = %{}
      listener  = {OtherListener, my_config}

      EventBus.mark_as_completed({listener, event_shadow})
      :ok

  """
  @spec mark_as_completed(listener_with_event_ref()) :: no_return()
  defdelegate mark_as_completed(listener_with_event_ref),
    to: Observation,
    as: :mark_as_completed

  @doc """
  Send the event processing skipped to the Observation Manager

  ## Examples

      EventBus.mark_as_skipped({MyEventListener, {:unmatched_occurred, "124"}})

      # For configurable listeners you must pass tuple of listener and config
      my_config = %{}
      listener  = {OtherListener, my_config}
      EventBus.mark_as_skipped({listener, {:unmatched_occurred, "124"}})
      :ok

  """
  @spec mark_as_skipped(listener_with_event_ref()) :: no_return()
  defdelegate mark_as_skipped(listener_with_event_ref),
    to: Observation,
    as: :mark_as_skipped
end
