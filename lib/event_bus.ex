defmodule EventBus do
  @moduledoc """
  Simple event bus implementation.
  """

  alias EventBus.EventManager
  alias EventBus.SubscriptionManager
  alias EventBus.EventStore
  alias EventBus.EventWatcher

  @doc """
  Send event to all listeners.

  ## Examples

      EventBus.notify({:webhook_received, %{"message" => "Hi all!"}})
      :ok

  """
  @spec notify({atom(), any()}) :: :ok
  def notify({event_type, _event_data} = event) do
    EventManager.notify(subscribers(event_type), event)
  end

  @doc """
  Subscribe to the bus.

  ## Examples

      EventBus.subscribe({MyEventListener, [".*"]})
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

  """
  @spec unsubscribe(any()) :: :ok
  defdelegate unsubscribe(listener), to: SubscriptionManager, as: :unsubscribe

  @doc """
  List the subscribers to the bus.

  ## Examples

      EventBus.subscribers()
      [MyEventListener]

  """
  @spec subscribers() :: list(any())
  defdelegate subscribers, to: SubscriptionManager, as: :subscribers

  @doc """
  List the subscribers to the bus with given event name.

  ## Examples

      EventBus.subscribers(:metrics_received)
      [MyEventListener]

  """
  @spec subscribers(atom() | String.t) :: list(any())
  defdelegate subscribers(event_name), to: SubscriptionManager, as: :subscribers

  @doc """
  Fetch event data

  ## Examples

      EventBus.fetch_event_data({:hello_received, "123"})

  """
  @spec fetch_event_data(tuple()) :: any()
  defdelegate fetch_event_data(event_shadow), to: EventStore, as: :fetch

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

  """
  @spec mark_as_skipped(tuple()) :: no_return()
  defdelegate mark_as_skipped(event_with_listener),
    to: EventWatcher, as: :mark_as_skipped
end
