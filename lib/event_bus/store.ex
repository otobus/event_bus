defmodule EventBus.Store do
  @moduledoc false

  ###########################################################################
  # Event store is a storage handler for events. It allows to create and delete
  # stores for a topic. And allows fetching, deleting and saving events for the
  # topic.
  ###########################################################################

  use GenServer
  alias EventBus.Model.Event

  @backend Application.get_env(
             :event_bus,
             :store_backend,
             EventBus.Service.Store
           )

  @doc false
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  def init(args),
    do: {:ok, args}

  @doc """
  Register a topic to the store
  """
  @spec register_topic(String.t() | atom()) :: no_return()
  def register_topic(topic),
    do: GenServer.cast(__MODULE__, {:register_topic, topic})

  @doc """
  Unregister the topic from the store
  """
  @spec unregister_topic(String.t() | atom()) :: no_return()
  def unregister_topic(topic),
    do: GenServer.cast(__MODULE__, {:unregister_topic, topic})

  @doc """
  Delete an event from the store
  """
  @spec delete({atom(), String.t() | integer()}) :: no_return()
  def delete({topic, id}),
    do: GenServer.cast(__MODULE__, {:delete, {topic, id}})

  @doc """
  Save an event to the store
  """
  @spec save(Event.t()) :: :ok
  def save(%Event{} = event),
    do: GenServer.call(__MODULE__, {:save, event})

  ###########################################################################
  # DELEGATIONS
  ###########################################################################

  @doc """
  Fetch an event from the store
  """
  @spec fetch({atom(), String.t() | integer()}) :: any()
  defdelegate fetch(event_shadow),
    to: @backend,
    as: :fetch

  ###########################################################################
  # PRIVATE API
  ###########################################################################

  @doc false
  @spec handle_cast({:register_topic, String.t() | atom()}, nil) :: no_return()
  def handle_cast({:register_topic, topic}, state) do
    @backend.register_topic(topic)
    {:noreply, state}
  end

  @spec handle_cast({:unregister_topic, String.t() | atom()}, nil)
    :: no_return()
  def handle_cast({:unregister_topic, topic}, state) do
    @backend.unregister_topic(topic)
    {:noreply, state}
  end

  @spec handle_cast({:delete, {atom(), String.t() | integer()}}, nil)
    :: no_return()
  def handle_cast({:delete, {topic, id}}, state) do
    @backend.delete({topic, id})
    {:noreply, state}
  end

  @doc false
  @spec handle_call({:save, Event.t()}, any(), nil) :: no_return()
  def handle_call({:save, event}, _from, state) do
    @backend.save(event)
    {:reply, :ok, state}
  end
end
