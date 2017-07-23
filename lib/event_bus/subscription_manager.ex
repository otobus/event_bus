defmodule EventBus.SubscriptionManager do
  @moduledoc """
  Subscription Manager
  """

  use GenServer

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, []}
  end

  @doc false
  def subscribe(listener) do
    GenServer.cast(__MODULE__, {:subscribe, listener})
  end

  @doc false
  def unsubscribe(listener) do
    GenServer.cast(__MODULE__, {:unsubscribe, listener})
  end

  @doc false
  def subscribers do
    GenServer.call(__MODULE__, {:subscribers})
  end

  @doc false
  def handle_cast({:subscribe, listener}, state) do
    state =
      if Enum.any?(state, fn old_listener -> old_listener == listener end) do
        state
      else
        [listener | state]
      end
    {:noreply, state}
  end

  @doc false
  def handle_cast({:unsubscribe, listener}, state) do
    {:noreply, List.delete(state, listener)}
  end

  @doc false
  def handle_call({:subscribers}, _from, state) do
    {:reply, state, state}
  end
end
