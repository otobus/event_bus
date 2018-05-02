defmodule EventBus.Manager.Subscription do
  @moduledoc false

  ###########################################################################
  # Subscription manager
  ###########################################################################

  use GenServer
  alias EventBus.Service.Subscription, as: SubscriptionService

  @backend SubscriptionService

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def init(args) do
    {:ok, args}
  end

  @doc """
  Subscribe the listener to topics
  """
  @spec subscribed?({tuple() | module(), list()}) :: no_return()
  def subscribed?({_listener, _topics} = subscriber) do
    GenServer.call(__MODULE__, {:subscribed?, subscriber})
  end

  @doc """
  Subscribe the listener to topics
  """
  @spec subscribe({tuple() | module(), list()}) :: no_return()
  def subscribe({listener, topics}) do
    GenServer.cast(__MODULE__, {:subscribe, {listener, topics}})
  end

  @doc """
  Unsubscribe the listener
  """
  @spec unsubscribe({tuple() | module()}) :: no_return()
  def unsubscribe(listener) do
    GenServer.cast(__MODULE__, {:unsubscribe, listener})
  end

  @doc """
  Set listeners to the topic
  """
  @spec register_topic(atom()) :: no_return()
  def register_topic(topic) do
    GenServer.cast(__MODULE__, {:register_topic, topic})
  end

  @doc """
  Unset listeners from the topic
  """
  @spec unregister_topic(atom()) :: no_return()
  def unregister_topic(topic) do
    GenServer.cast(__MODULE__, {:unregister_topic, topic})
  end

  ###########################################################################
  # DELEGATIONS
  ###########################################################################

  @doc """
  Fetch listeners
  """
  @spec subscribers() :: list(any())
  defdelegate subscribers,
    to: @backend,
    as: :subscribers

  @doc """
  Fetch listeners of the topic
  """
  @spec subscribers(String.t() | atom()) :: list(any())
  defdelegate subscribers(topic),
    to: @backend,
    as: :subscribers

  ###########################################################################
  # PRIVATE API
  ###########################################################################

  @doc false
  @spec handle_call({:subscribed?, tuple()}, any(), term())
    :: {:reply, boolean(), term()}
  def handle_call({:subscribed?, subscriber}, _from, state) do
    {:reply, @backend.subscribed?(subscriber), state}
  end

  @doc false
  @spec handle_cast({:subscribe, tuple()}, term()) :: no_return()
  def handle_cast({:subscribe, {listener, topics}}, state) do
    @backend.subscribe({listener, topics})
    {:noreply, state}
  end

  @doc false
  @spec handle_cast({:unsubscribe, tuple() | module()}, term()) :: no_return()
  def handle_cast({:unsubscribe, listener}, state) do
    @backend.unsubscribe(listener)
    {:noreply, state}
  end

  @doc false
  @spec handle_cast({:register_topic, atom()}, term()) :: no_return()
  def handle_cast({:register_topic, topic}, state) do
    @backend.register_topic(topic)
    {:noreply, state}
  end

  @doc false
  @spec handle_cast({:unregister_topic, atom()}, term()) :: no_return()
  def handle_cast({:unregister_topic, topic}, state) do
    @backend.unregister_topic(topic)
    {:noreply, state}
  end
end
