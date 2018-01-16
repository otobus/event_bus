defmodule EventBus.Service.Store do
  @moduledoc false

  alias EventBus.Model.Event
  alias :ets, as: Ets

  @prefix "eb_es_"

  @doc false
  @spec register_topic(String.t | atom()) :: no_return()
  def register_topic(topic) do
    table_name = table_name(topic)
    all_tables = :ets.all()
    unless Enum.any?(all_tables, fn table -> table == table_name end) do
      opts = [:set, :public, :named_table, {:read_concurrency, true}]
      Ets.new(table_name, opts)
    end
  end

  @doc false
  @spec unregister_topic(String.t | atom()) :: no_return()
  def unregister_topic(topic) do
    table_name = table_name(topic)
    all_tables = :ets.all()
    if Enum.any?(all_tables, fn table -> table == table_name end) do
      Ets.delete(table_name)
    end
  end

  @doc false
  @spec fetch({atom(), String.t | integer()}) :: any()
  def fetch({topic, id}) do
    case Ets.lookup(table_name(topic), id) do
      [{_, %Event{} = event}] -> event
      _ -> nil
    end
  end

  @doc false
  @spec delete({atom(), String.t | integer()}) :: no_return()
  def delete({topic, id}) do
    Ets.delete(table_name(topic), id)
  end

  @doc false
  @spec save(Event.t) :: no_return()
  def save(%Event{id: id, topic: topic} = event) do
    Ets.insert(table_name(topic), {id, event})
    :ok
  end

  defp table_name(topic),
    do: :"#{@prefix}#{topic}"
end
