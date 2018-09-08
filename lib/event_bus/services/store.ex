defmodule EventBus.Service.Store do
  @moduledoc false

  alias EventBus.Model.Event
  alias :ets, as: Ets

  @ets_opts [:set, :public, :named_table, {:read_concurrency, true}]
  @prefix "eb_es_"

  @doc false
  @spec exist?(atom()) :: boolean()
  def exist?(topic) do
    table_name = table_name(topic)
    all_tables = Ets.all()
    Enum.any?(all_tables, fn table -> table == table_name end)
  end

  @doc false
  @spec register_topic(String.t() | atom()) :: no_return()
  def register_topic(topic) do
    unless exist?(topic), do: Ets.new(table_name(topic), @ets_opts)
  end

  @doc false
  @spec unregister_topic(String.t() | atom()) :: no_return()
  def unregister_topic(topic) do
    if exist?(topic), do: Ets.delete(table_name(topic))
  end

  @doc false
  @spec fetch({atom(), String.t() | integer()}) :: Event.t() | nil
  def fetch({topic, id}) do
    case Ets.lookup(table_name(topic), id) do
      [{_, %Event{} = event}] -> event
      _ -> nil
    end
  end

  @doc false
  @spec fetch_data({atom(), String.t() | integer()}) :: any()
  def fetch_data({topic, id}) do
    event = fetch({topic, id}) || %{}
    Map.get(event, :data)
  end

  @doc false
  @spec delete({atom(), String.t() | integer()}) :: no_return()
  def delete({topic, id}) do
    Ets.delete(table_name(topic), id)
  end

  @doc false
  @spec create(Event.t()) :: no_return()
  def create(%Event{id: id, topic: topic} = event) do
    Ets.insert(table_name(topic), {id, event})
    :ok
  end

  defp table_name(topic) do
    String.to_atom("#{@prefix}#{topic}")
  end
end
