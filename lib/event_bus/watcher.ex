defmodule EventBus.Watcher do
  @moduledoc false

  ###########################################################################
  # Event Watcher module is a helper to get info for the events and also an
  # organizer for the events happened in time. It automatically deletes
  # processed events from the ETS table. Event listeners are responsible for
  # notifying the Event Watcher on completions and skips.
  ###########################################################################

  use GenServer

  @backend Application.get_env(
             :event_bus,
             :watcher_backend,
             EventBus.Service.Watcher
           )

  @doc false
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  def init(args),
    do: {:ok, args}

  @doc """
  Register a topic to the watcher
  """
  @spec register_topic(String.t()) :: no_return()
  def register_topic(topic),
    do: GenServer.cast(__MODULE__, {:register_topic, topic})

  @doc """
  Unregister a topic from the watcher
  """
  @spec unregister_topic(String.t() | atom()) :: no_return()
  def unregister_topic(topic),
    do: GenServer.cast(__MODULE__, {:unregister_topic, topic})

  @doc """
  Mark event as completed on the watcher
  """
  @spec mark_as_completed(tuple()) :: no_return()
  def mark_as_completed({listener, topic, id}),
    do: GenServer.cast(__MODULE__, {:mark_as_completed, {listener, topic, id}})

  @doc """
  Mark event as skipped on the watcher
  """
  @spec mark_as_skipped(tuple()) :: no_return()
  def mark_as_skipped({listener, topic, id}),
    do: GenServer.cast(__MODULE__, {:mark_as_skipped, {listener, topic, id}})

  @doc """
  Create an watcher
  """
  @spec create(tuple()) :: no_return()
  def create({listeners, topic, id}),
    do: GenServer.call(__MODULE__, {:save, {topic, id}, {listeners, [], []}})

  ###########################################################################
  # DELEGATIONS
  ###########################################################################

  @doc """
  Fetch the watcher
  """
  @spec fetch({atom(), String.t() | integer()}) :: tuple() | nil
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

  @doc false
  @spec handle_cast({:mark_as_completed, tuple()}, nil) :: no_return()
  def handle_cast({:mark_as_completed, {listener, topic, id}}, state) do
    @backend.mark_as_completed({listener, topic, id})
    {:noreply, state}
  end

  @doc false
  @spec handle_cast({:mark_as_skipped, tuple()}, nil) :: no_return()
  def handle_cast({:mark_as_skipped, {listener, topic, id}}, state) do
    @backend.mark_as_skipped({listener, topic, id})
    {:noreply, state}
  end

  @doc false
  @spec handle_call({:save, tuple(), tuple()}, any(), nil) :: no_return()
  def handle_call({:save, {topic, id}, watcher}, _from, state) do
    @backend.save({topic, id}, watcher)
    {:reply, :ok, state}
  end
end
