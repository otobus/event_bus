defmodule EventBus.Manager.Subscription do
  @moduledoc false

  ###########################################################################
  # Subscription manager
  ###########################################################################

  use GenServer

  alias EventBus.Service.Subscription, as: SubscriptionService

  @typep listener :: EventBus.listener()
  @typep listener_list :: EventBus.listener_list()
  @typep listener_with_topic_patterns :: EventBus.listener_with_topic_patterns()
  @typep topic :: EventBus.topic()

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
  Does the listener subscribe to topic_patterns?
  """
  @spec subscribed?(listener_with_topic_patterns()) :: boolean()
  def subscribed?({_listener, _topic_patterns} = subscriber) do
    GenServer.call(__MODULE__, {:subscribed?, subscriber})
  end

  @doc """
  Subscribe the listener to topic_patterns
  """
  @spec subscribe(listener_with_topic_patterns()) :: :ok
  def subscribe({listener, topic_patterns}) do
    GenServer.cast(__MODULE__, {:subscribe, {listener, topic_patterns}})
  end

  @doc """
  Unsubscribe the listener
  """
  @spec unsubscribe(listener()) :: :ok
  def unsubscribe(listener) do
    GenServer.cast(__MODULE__, {:unsubscribe, listener})
  end

  @doc """
  Set listeners to the topic
  """
  @spec register_topic(topic()) :: :ok
  def register_topic(topic) do
    GenServer.cast(__MODULE__, {:register_topic, topic})
  end

  @doc """
  Unset listeners from the topic
  """
  @spec unregister_topic(topic()) :: :ok
  def unregister_topic(topic) do
    GenServer.cast(__MODULE__, {:unregister_topic, topic})
  end

  ###########################################################################
  # DELEGATIONS
  ###########################################################################

  @doc """
  Fetch listeners
  """
  @spec subscribers() :: listener_list()
  defdelegate subscribers,
    to: @backend,
    as: :subscribers

  @doc """
  Fetch listeners of the topic
  """
  @spec subscribers(topic()) :: listener_list()
  defdelegate subscribers(topic),
    to: @backend,
    as: :subscribers

  ###########################################################################
  # PRIVATE API
  ###########################################################################

  @doc false
  @spec handle_call({:subscribed?, listener_with_topic_patterns()}, any(), term())
    :: {:reply, boolean(), term()}
  def handle_call({:subscribed?, subscriber}, _from, state) do
    {:reply, @backend.subscribed?(subscriber), state}
  end

  @doc false
  @spec handle_cast({:subscribe, listener_with_topic_patterns()}, term())
    :: no_return()
  def handle_cast({:subscribe, {listener, topic_patterns}}, state) do
    @backend.subscribe({listener, topic_patterns})
    {:noreply, state}
  end

  @doc false
  @spec handle_cast({:unsubscribe, listener()}, term()) :: no_return()
  def handle_cast({:unsubscribe, listener}, state) do
    @backend.unsubscribe(listener)
    {:noreply, state}
  end

  @doc false
  @spec handle_cast({:register_topic, topic()}, term()) :: no_return()
  def handle_cast({:register_topic, topic}, state) do
    @backend.register_topic(topic)
    {:noreply, state}
  end

  @doc false
  @spec handle_cast({:unregister_topic, topic()}, term()) :: no_return()
  def handle_cast({:unregister_topic, topic}, state) do
    @backend.unregister_topic(topic)
    {:noreply, state}
  end
end
