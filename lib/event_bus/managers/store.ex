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
  @spec exist?(String.t() | atom()) :: boolean()
  def exist?(topic) do
    GenServer.call(__MODULE__, {:exist?, topic})
  end

  @doc """
  Register a topic to the store
  """
  @spec register_topic(String.t() | atom()) :: :ok
  def register_topic(topic) do
    GenServer.call(__MODULE__, {:register_topic, topic})
  end

  @doc """
  Unregister the topic from the store
  """
  @spec unregister_topic(String.t() | atom()) :: :ok
  def unregister_topic(topic) do
    GenServer.call(__MODULE__, {:unregister_topic, topic})
  end

  @doc """
  Save an event to the store
  """
  @spec create(Event.t()) :: :ok
  def create(%Event{} = event) do
    GenServer.call(__MODULE__, {:create, event})
  end

  @doc """
  Delete an event from the store
  """
  @spec delete({atom(), String.t() | integer()}) :: no_return()
  def delete({topic, id}) do
    GenServer.cast(__MODULE__, {:delete, {topic, id}})
  end

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
  @spec handle_call({:register_topic, atom()}, any(), term())
    :: {:reply, :ok, term()}
  def handle_call({:register_topic, topic}, _from, state) do
    @backend.register_topic(topic)
    {:reply, :ok, state}
  end

  @spec handle_call({:unregister_topic, atom()}, any(), term())
    :: {:reply, :ok, term()}
  def handle_call({:unregister_topic, topic}, _from, state) do
    @backend.unregister_topic(topic)
    {:reply, :ok, state}
  end

  @doc false
  @spec handle_call({:exist?, atom()}, any(), term())
    :: {:reply, boolean(), nil}
  def handle_call({:exist?, topic}, _from, state) do
    {:reply, @backend.exist?(topic), state}
  end

  @doc false
  @spec handle_call({:create, Event.t()}, any(), term()) :: no_return()
  def handle_call({:create, event}, _from, state) do
    @backend.create(event)
    {:reply, :ok, state}
  end

  @spec handle_cast({:delete, {atom(), String.t() | integer()}}, term())
    :: no_return()
  def handle_cast({:delete, {topic, id}}, state) do
    @backend.delete({topic, id})
    {:noreply, state}
  end
end
