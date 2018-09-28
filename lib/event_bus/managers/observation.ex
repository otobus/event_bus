defmodule EventBus.Manager.Observation do
  @moduledoc false

  ###########################################################################
  # Event Observation module is a helper to get info for the events and also an
  # organizer for the events happened in time. It automatically deletes
  # processed events from the ETS table. Event listeners are responsible for
  # notifying the Event Observation on completions and skips.
  ###########################################################################

  use GenServer

  alias EventBus.Service.Observation, as: ObservationService

  @typep event_shadow :: EventBus.event_shadow()
  @typep listener_list :: EventBus.listener_list()
  @typep listener_list_with_event_shadow :: {listener_list(), event_shadow()}
  @typep listener_with_event_ref :: EventBus.listener_with_event_ref()
  @typep topic :: EventBus.topic()
  @typep watcher :: {listener_list(), listener_list(), listener_list()}

  @backend ObservationService

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
  Register a topic to the watcher
  """
  @spec register_topic(topic()) :: :ok
  def register_topic(topic) do
    GenServer.call(__MODULE__, {:register_topic, topic})
  end

  @doc """
  Unregister a topic from the watcher
  """
  @spec unregister_topic(topic()) :: :ok
  def unregister_topic(topic) do
    GenServer.call(__MODULE__, {:unregister_topic, topic})
  end

  @doc """
  Mark event as completed on the watcher
  """
  @spec mark_as_completed(listener_with_event_ref()) :: :ok
  def mark_as_completed({listener, topic, id}) do
    GenServer.cast(__MODULE__, {:mark_as_completed, {listener, {topic, id}}})
  end

  def mark_as_completed({listener, {topic, id}}) do
    GenServer.cast(__MODULE__, {:mark_as_completed, {listener, {topic, id}}})
  end

  @doc """
  Mark event as skipped on the watcher
  """
  @spec mark_as_skipped(listener_with_event_ref()) :: :ok
  def mark_as_skipped({listener, topic, id}) do
    GenServer.cast(__MODULE__, {:mark_as_skipped, {listener, {topic, id}}})
  end

  def mark_as_skipped({listener, {topic, id}}) do
    GenServer.cast(__MODULE__, {:mark_as_skipped, {listener, {topic, id}}})
  end

  @doc """
  Create an watcher
  """
  @spec create(listener_list_with_event_shadow()) :: :ok
  def create({listeners, {topic, id}}) do
    GenServer.call(__MODULE__, {:save, {topic, id}, {listeners, [], []}})
  end

  ###########################################################################
  # DELEGATIONS
  ###########################################################################

  @doc """
  Fetch the watcher
  """
  @spec fetch(event_shadow()) :: any()
  defdelegate fetch(event_shadow),
    to: @backend,
    as: :fetch

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
  @spec handle_call({:save, event_shadow(), watcher()}, any(), term())
    :: {:reply, :ok, term()}
  def handle_call({:save, {topic, id}, watcher}, _from, state) do
    @backend.save({topic, id}, watcher)
    {:reply, :ok, state}
  end

  @doc false
  @spec handle_cast({:mark_as_completed, listener_with_event_ref()}, term())
    :: no_return()
  def handle_cast({:mark_as_completed, {listener, {topic, id}}}, state) do
    @backend.mark_as_completed({listener, {topic, id}})
    {:noreply, state}
  end

  @doc false
  @spec handle_cast({:mark_as_skipped, listener_with_event_ref()}, term())
    :: no_return()
  def handle_cast({:mark_as_skipped, {listener, {topic, id}}}, state) do
    @backend.mark_as_skipped({listener, {topic, id}})
    {:noreply, state}
  end
end
