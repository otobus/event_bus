defmodule EventBus.Service.Observation do
  @moduledoc false

  alias EventBus.Manager.Store, as: StoreManager
  alias :ets, as: Ets

  @ets_opts [
    :set,
    :public,
    :named_table,
    {:write_concurrency, true},
    {:read_concurrency, true}
  ]
  @prefix "eb_ew_"

  @doc false
  @spec exist?(atom()) :: boolean()
  def exist?(topic) do
    table_name = table_name(topic)
    all_tables = Ets.all()
    Enum.any?(all_tables, fn table -> table == table_name end)
  end

  @doc false
  @spec register_topic(atom()) :: no_return()
  def register_topic(topic) do
    unless exist?(topic), do: Ets.new(table_name(topic), @ets_opts)
  end

  @doc false
  @spec unregister_topic(atom()) :: no_return()
  def unregister_topic(topic) do
    if exist?(topic), do: Ets.delete(table_name(topic))
  end

  @doc false
  @spec mark_as_completed(tuple()) :: no_return()
  def mark_as_completed({listener, topic, id}) do
    {listeners, completers, skippers} = fetch({topic, id})
    save_or_delete({topic, id}, {listeners, [listener | completers], skippers})
  end

  @doc false
  @spec mark_as_skipped(tuple()) :: no_return()
  def mark_as_skipped({listener, topic, id}) do
    {listeners, completers, skippers} = fetch({topic, id})
    save_or_delete({topic, id}, {listeners, completers, [listener | skippers]})
  end

  @doc false
  @spec fetch(tuple()) :: any()
  def fetch({topic, id}) do
    case Ets.lookup(table_name(topic), id) do
      [{_, data}] -> data
      _ -> nil
    end
  end

  @doc false
  @spec save(tuple(), tuple()) :: :ok
  def save({topic, id}, watcher) do
    save_or_delete({topic, id}, watcher)
    :ok
  end

  @spec complete?(tuple()) :: boolean()
  defp complete?({listeners, completers, skippers}) do
    length(listeners) == length(completers) + length(skippers)
  end

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
    StoreManager.delete({topic, id})
    Ets.delete(table_name(topic), id)
  end

  @spec table_name(atom()) :: atom()
  defp table_name(name) do
    :"#{@prefix}#{name}"
  end
end
