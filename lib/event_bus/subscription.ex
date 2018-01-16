defmodule EventBus.Subscription do
  @moduledoc false

  ###########################################################################
  # Subscription manager
  ###########################################################################

  use GenServer

  @backend Application.get_env(:event_bus, :subscription_backend,
    EventBus.Service.Subscription)

  @doc false
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc """
  Subscribe the listener to topics
  """
  @spec subscribe({tuple() | module(), list()}) :: no_return()
  def subscribe({listener, topics}),
    do: GenServer.cast(__MODULE__, {:subscribe, {listener, topics}})

  @doc """
  Unsubscribe the listener
  """
  @spec unsubscribe({tuple() | module()}) :: no_return()
  def unsubscribe(listener),
    do: GenServer.cast(__MODULE__, {:unsubscribe, listener})

  @doc """
  Set listeners to the topic
  """
  @spec register_topic(atom()) :: no_return()
  def register_topic(topic),
    do: GenServer.cast(__MODULE__, {:register_topic, topic})

  @doc """
  Unset listeners from the topic
  """
  @spec unregister_topic(atom()) :: no_return()
  def unregister_topic(topic),
    do: GenServer.cast(__MODULE__, {:unregister_topic, topic})

  ###########################################################################
  # DELEGATIONS
  ###########################################################################

  @doc """
  Fetch listeners
  """
  @spec subscribers() :: list(any())
  defdelegate subscribers,
    to: @backend, as: :subscribers

  @doc """
  Fetch listeners of the topic
  """
  @spec subscribers(String.t | atom()) :: list(any())
  defdelegate subscribers(topic),
    to: @backend, as: :subscribers

  ###########################################################################
  # PRIVATE API
  ###########################################################################

  @doc false
  def handle_cast({:subscribe, {listener, topics}}, state) do
    @backend.subscribe({listener, topics})
    {:noreply, state}
  end

  @doc false
  def handle_cast({:unsubscribe, listener}, state) do
    @backend.unsubscribe(listener)
    {:noreply, state}
  end

  @doc false
  def handle_cast({:register_topic, topic}, state) do
    @backend.register_topic(topic)
    {:noreply, state}
  end

  @doc false
  def handle_cast({:unregister_topic, topic}, state) do
    @backend.unregister_topic(topic)
    {:noreply, state}
  end
end
