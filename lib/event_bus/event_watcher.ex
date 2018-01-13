defmodule EventBus.EventWatcher do
  @moduledoc """
  Event Watcher module is a helper to get info for the events and also an
  organizer for the events happened in time. It automatically deletes processed
  events from the ETS table. Event listeners are responsible for notifying the
  Event Watcher on completions and skips.
  """

  require Logger
  use GenServer
  alias EventBus.EventStore
  alias :ets, as: Ets

  @prefix "eb_ew_"

  @doc false
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  @spec register_topic(String.t) :: no_return()
  def register_topic(topic),
    do: GenServer.cast(__MODULE__, {:register_topic, topic})

  @doc false
  @spec unregister_topic(String.t | atom()) :: no_return()
  def unregister_topic(topic),
    do: GenServer.cast(__MODULE__, {:unregister_topic, topic})

  @doc false
  @spec create(tuple()) :: no_return()
  def create({listeners, topic, id}),
    do: GenServer.call(__MODULE__, {:save, {topic, id}, {listeners, [], []}})

  @doc false
  @spec mark_as_completed(tuple()) :: no_return()
  def mark_as_completed({listener, topic, id}),
    do: GenServer.cast(__MODULE__, {:mark_as_completed, {listener, topic, id}})

  @doc false
  @spec mark_as_skipped(tuple()) :: no_return()
  def mark_as_skipped({listener, topic, id}),
    do: GenServer.cast(__MODULE__, {:mark_as_skipped, {listener, topic, id}})

  @doc false
  @spec fetch(tuple()) :: any()
  def fetch({topic, id}) do
    case Ets.lookup(table_name(topic), id) do
      [{_, data}] -> data
      _ -> nil
    end
  end

  @doc false
  @spec handle_cast({:register_topic, String.t | atom()}, nil) :: no_return()
  def handle_cast({:register_topic, topic}, state) do
    table_name = table_name(topic)
    all_tables = :ets.all()
    unless Enum.any?(all_tables, fn table -> table == table_name end) do
      opts = [:set, :public, :named_table, {:write_concurrency, true},
        {:read_concurrency, true}]
      Ets.new(table_name, opts)
    end
    {:noreply, state}
  end
  @spec handle_cast({:unregister_topic, String.t | atom()}, nil) :: no_return()
  def handle_cast({:unregister_topic, topic}, state) do
    table_name = table_name(topic)
    all_tables = :ets.all()
    if Enum.any?(all_tables, fn table -> table == table_name end) do
      Ets.delete(table_name)
    end
    {:noreply, state}
  end
  @doc false
  @spec handle_cast({:mark_as_completed, tuple()}, nil) :: no_return()
  def handle_cast({:mark_as_completed, {listener, topic, id}}, state) do
    {listeners, completers, skippers} = fetch({topic, id})
    save_or_delete({topic, id}, {listeners, [listener | completers],
      skippers})
    {:noreply, state}
  end
  @doc false
  @spec handle_cast({:mark_as_skipped, tuple()}, nil) :: no_return()
  def handle_cast({:mark_as_skipped, {listener, topic, id}}, state) do
    {listeners, completers, skippers} = fetch({topic, id})
    save_or_delete({topic, id}, {listeners, completers,
      [listener | skippers]})
    {:noreply, state}
  end

  @doc false
  @spec handle_call({:save, tuple(), tuple()}, any(), nil) :: no_return()
  def handle_call({:save, {topic, id}, watcher}, _from, state) do
    save_or_delete({topic, id}, watcher)
    {:reply, :ok, state}
  end

  @spec complete?(tuple()) :: boolean()
  defp complete?({listeners, completers, skippers}),
    do: length(listeners) == length(completers) + length(skippers)

  @spec save_or_delete(tuple(), tuple()) :: no_return()
  defp save_or_delete({topic, id}, watcher) do
    if complete?(watcher) do
      delete_with_relations({topic, id})
    else
      Ets.insert(table_name(topic), {id, watcher})
    end
  end

  @spec delete_with_relations(tuple()) :: no_return()
  defp delete_with_relations({topic, id}) do
    EventStore.delete({topic, id})
    Ets.delete(table_name(topic), id)
  end

  @spec table_name(String.t) :: atom()
  defp table_name(name),
    do: :"#{@prefix}#{name}"
end
