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
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  @spec register_event(String.t) :: no_return()
  def register_event(name) do
    GenServer.cast(__MODULE__, {:register_event, name})
  end

  @doc false
  @spec create(tuple()) :: no_return()
  def create({processors, type, key}) do
    GenServer.cast(__MODULE__, {:save, {type, key}, {processors, [], []}})
  end

  @doc false
  @spec mark_as_completed(tuple()) :: no_return()
  def mark_as_completed({processor, type, key}) do
    GenServer.cast(__MODULE__, {:mark_as_completed, {processor, type, key}})
  end

  @doc false
  @spec mark_as_skipped(tuple()) :: no_return()
  def mark_as_skipped({processor, type, key}) do
    GenServer.cast(__MODULE__, {:mark_as_skipped, {processor, type, key}})
  end

  @doc false
  @spec fetch(tuple()) :: any()
  def fetch({type, key}) do
    case Ets.lookup(table_name(type), key) do
      [{_, data}] -> data
      _ -> nil
    end
  end

  @doc false
  def handle_cast({:register_event, name}, state) do
    table_name = table_name(name)
    Ets.new(table_name, [:set, :public, :named_table])
    {:noreply, state}
  end
  @doc false
  @spec handle_cast({:mark_as_completed, tuple()}, nil) :: no_return()
  def handle_cast({:mark_as_completed, {processor, type, key}}, state) do
    {processors, completers, skippers} = fetch({type, key})
    save_or_delete({type, key}, {processors, [processor | completers],
      skippers})
    {:noreply, state}
  end
  @doc false
  @spec handle_cast({:mark_as_skipped, tuple()}, nil) :: no_return()
  def handle_cast({:mark_as_skipped, {processor, type, key}}, state) do
    {processors, completers, skippers} = fetch({type, key})
    save_or_delete({type, key}, {processors, completers,
      [processor | skippers]})
    {:noreply, state}
  end
  @doc false
  @spec handle_cast({:save, tuple(), tuple()}, nil) :: no_return()
  def handle_cast({:save, {type, key}, watcher}, state) do
    save_or_delete({type, key}, watcher)
    {:noreply, state}
  end

  @spec complete?(tuple()) :: boolean()
  defp complete?({processors, completers, skippers}) do
    length(processors) == length(completers) + length(skippers)
  end

  @spec save_or_delete(tuple(), tuple()) :: no_return()
  defp save_or_delete({type, key}, watcher) do
    if complete?(watcher) do
      delete_with_relations({type, key})
    else
      Ets.insert(table_name(type), {key, watcher})
    end
  end

  @spec delete_with_relations(tuple()) :: no_return()
  defp delete_with_relations({type, key}) do
    EventStore.delete({type, key})
    Ets.delete(table_name(type), key)
  end

  @spec table_name(String.t) :: atom()
  defp table_name(name) do
    :"#{@prefix}#{name}"
  end
end
