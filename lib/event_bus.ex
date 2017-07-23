defmodule EventBus do
  @moduledoc """
  Simple event bus implementation.
  """

  alias EventBus.EventManager
  alias EventBus.SubscriptionManager

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
end
