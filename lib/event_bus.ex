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
  @spec notify({:atom, any()}) :: :ok
  def notify({_event_type, _event_data} = event) do
    EventManager.notify(subscribers(), event)
  end

  @doc """
  Subscribe to the bus.

  ## Examples

      EventBus.subscribe(MyEventListener)
      :ok

  """
  @spec subscribe(any()) :: :ok
  defdelegate subscribe(listener), to: SubscriptionManager, as: :subscribe

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
  Fetc event data

  ## Examples

      EventBus.fetch_event_data({:hello_received, "123"})

  """
  @spec fetch_event_data(tuple()) :: any()
  defdelegate fetch_event_data(event_shadow), to: EventStore, as: :fetch

  @doc """
  Send the event processing completed to the watcher

  ## Examples

      EventBus.complete({MyEventListener, :hello_received, "123"})

  """
  @spec complete(tuple()) :: no_return()
  defdelegate complete(event_with_listener), to: EventWatcher, as: :complete

  @doc """
  Send the event processing skipped to the watcher

  ## Examples

      EventBus.skip({MyEventListener, :unmatched_occurred, "124"})

  """
  @spec skip(tuple()) :: no_return()
  defdelegate skip(event_with_listener), to: EventWatcher, as: :skip
end
