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
  def subscribe({listener, topics}) do
    GenServer.cast(__MODULE__, {:subscribe, {listener, topics}})
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
  def handle_cast({:subscribe, {listener, topics}}, state) do
    state =
      if List.keymember?(state, listener, 0) do
        List.keyreplace(state, listener, 0, {listener, topics})
      else
        [{listener, topics} | state]
      end
    {:noreply, state}
  end

  @doc false
  def handle_cast({:unsubscribe, listener}, state) do
    {:noreply, List.keydelete(state, listener, 0)}
  end

  @doc false
  def handle_call({:subscribers}, _from, state) do
    {:reply, state, state}
  end
end
