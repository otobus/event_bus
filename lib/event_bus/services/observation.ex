defmodule EventBus.Service.Observation do
  @moduledoc false

  require Logger

  alias EventBus.Manager.Store, as: StoreManager
  alias :ets, as: Ets

  @typep event_shadow :: EventBus.event_shadow()
  @typep subscribers :: EventBus.subscribers()
  @typep subscriber_with_event_ref :: EventBus.subscriber_with_event_ref()
  @typep topic :: EventBus.topic()
  @typep watcher :: {subscribers(), subscribers(), subscribers()}

  @ets_opts [
    :set,
    :public,
    :named_table,
    {:write_concurrency, true},
    {:read_concurrency, true}
  ]
  @prefix "eb_ew_"

  @doc false
  @spec exist?(topic()) :: boolean()
  def exist?(topic) do
    table_name = table_name(topic)
    all_tables = Ets.all()
    Enum.any?(all_tables, fn table -> table == table_name end)
  end

  @doc false
  @spec register_topic(topic()) :: :ok
  def register_topic(topic) do
    unless exist?(topic), do: Ets.new(table_name(topic), @ets_opts)
    :ok
  end

  @doc false
  @spec unregister_topic(topic()) :: :ok
  def unregister_topic(topic) do
    if exist?(topic), do: Ets.delete(table_name(topic))
    :ok
  end

  @doc false
  @spec mark_as_completed(subscriber_with_event_ref()) :: :ok
  def mark_as_completed({subscriber, event_shadow}) do
    case fetch(event_shadow) do
      {subscribers, completers, skippers} ->
        save_or_delete(event_shadow, {subscribers, [subscriber | completers], skippers})
        nil -> :ok
    end
  end

  @doc false
  @spec mark_as_skipped(subscriber_with_event_ref()) :: :ok
  def mark_as_skipped({subscriber, event_shadow}) do
    case fetch(event_shadow) do
      {subscribers, completers, skippers} ->
        save_or_delete(event_shadow, {subscribers, completers, [subscriber | skippers]})
      nil -> :ok
    end
  end

  @doc false
  @spec fetch(event_shadow()) :: {subscribers(), subscribers(), subscribers()} | nil
  def fetch({topic, id}) do
    case Ets.lookup(table_name(topic), id) do
      [{_, data}] -> data
      _ ->
        Logger.log(:info, fn ->
          "[EVENTBUS][OBSERVATION]\s#{topic}.#{id}.ets_fetch_error"
        end)

        nil
    end
  end

  @doc false
  @spec save(event_shadow(), watcher()) :: :ok
  def save({topic, id}, watcher) do
    save_or_delete({topic, id}, watcher)
  end

  @spec complete?(watcher()) :: boolean()
  defp complete?({subscribers, completers, skippers}) do
    length(subscribers) == length(completers) + length(skippers)
  end

  @spec save_or_delete(event_shadow(), watcher()) :: :ok
  defp save_or_delete({topic, id}, watcher) do
    if complete?(watcher) do
      delete_with_relations({topic, id})
    else
      Ets.insert(table_name(topic), {id, watcher})
    end

    :ok
  end

  @spec delete_with_relations(event_shadow()) :: :ok
  defp delete_with_relations({topic, id}) do
    StoreManager.delete({topic, id})
    Ets.delete(table_name(topic), id)

    :ok
  end

  @spec table_name(topic()) :: atom()
  defp table_name(topic) do
    String.to_atom("#{@prefix}#{topic}")
  end
end
