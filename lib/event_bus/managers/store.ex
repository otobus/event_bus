defmodule EventBus.Manager.Store do
  @moduledoc false

  ###########################################################################
  # Event store is a storage handler for events. It allows to create and delete
  # stores for a topic. And allows fetching, deleting and saving events for the
  # topic.
  ###########################################################################

  use GenServer

  alias EventBus.Model.Event
  alias EventBus.Service.Store, as: StoreService

  @typep event :: EventBus.event()
  @typep event_shadow :: EventBus.event_shadow()
  @typep topic :: EventBus.topic()

  @backend StoreService

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def init(args) do
    {:ok, args}
  end

  @doc """
  Check if the topic exists?
  It's important to keep this in blocking manner to prevent double creations in
  sub modules
  """
  @spec exist?(topic()) :: boolean()
  def exist?(topic) do
    GenServer.call(__MODULE__, {:exist?, topic})
  end

  @doc """
  Register a topic to the store
  """
  @spec register_topic(topic()) :: :ok
  def register_topic(topic) do
    GenServer.call(__MODULE__, {:register_topic, topic})
  end

  @doc """
  Unregister the topic from the store
  """
  @spec unregister_topic(topic()) :: :ok
  def unregister_topic(topic) do
    GenServer.call(__MODULE__, {:unregister_topic, topic})
  end

  @doc """
  Save an event to the store
  """
  @spec create(event()) :: :ok
  def create(%Event{} = event) do
    GenServer.call(__MODULE__, {:create, event})
  end

  @doc """
  Delete an event from the store
  """
  @spec delete(event_shadow()) :: :ok
  def delete({topic, id}) do
    GenServer.cast(__MODULE__, {:delete, {topic, id}})
  end

  ###########################################################################
  # DELEGATIONS
  ###########################################################################

  @doc """
  Fetch an event from the store
  """
  @spec fetch(event_shadow()) :: event() | nil
  defdelegate fetch(event_shadow),
    to: @backend,
    as: :fetch

  @doc """
  Fetch an event's data from the store
  """
  @spec fetch_data(event_shadow()) :: any()
  defdelegate fetch_data(event_shadow),
    to: @backend,
    as: :fetch_data

  ###########################################################################
  # PRIVATE API
  ###########################################################################

  @doc false
  @spec handle_call({:register_topic, topic()}, any(), term())
    :: {:reply, :ok, term()}
  def handle_call({:register_topic, topic}, _from, state) do
    @backend.register_topic(topic)
    {:reply, :ok, state}
  end

  @spec handle_call({:unregister_topic, topic()}, any(), term())
    :: {:reply, :ok, term()}
  def handle_call({:unregister_topic, topic}, _from, state) do
    @backend.unregister_topic(topic)
    {:reply, :ok, state}
  end

  @doc false
  @spec handle_call({:exist?, topic()}, any(), term())
    :: {:reply, boolean(), term()}
  def handle_call({:exist?, topic}, _from, state) do
    {:reply, @backend.exist?(topic), state}
  end

  @doc false
  @spec handle_call({:create, event()}, any(), term()) :: no_return()
  def handle_call({:create, event}, _from, state) do
    @backend.create(event)
    {:reply, :ok, state}
  end

  @spec handle_cast({:delete, event_shadow()}, term()) :: no_return()
  def handle_cast({:delete, {topic, id}}, state) do
    @backend.delete({topic, id})
    {:noreply, state}
  end
end
