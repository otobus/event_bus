defmodule EventBus.EventStore do
  @moduledoc """
  Event Manager
  """

  require Logger
  use GenServer
  alias EventBus.Model.Event
  alias :ets, as: Ets

  @prefix "eb_es_"

  @doc false
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  @spec register_topic(String.t | atom()) :: no_return()
  def register_topic(topic),
    do: GenServer.cast(__MODULE__, {:register_topic, topic})

  @doc false
  @spec unregister_topic(String.t | atom()) :: no_return()
  def unregister_topic(topic),
    do: GenServer.cast(__MODULE__, {:unregister_topic, topic})

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
  def delete({topic, id}),
    do: GenServer.cast(__MODULE__, {:delete, {topic, id}})

  @doc false
  @spec save(Event.t) :: :ok
  def save(%Event{} = event),
    do: GenServer.call(__MODULE__, {:save, event})

  @doc false
  @spec handle_cast({:register_topic, String.t | atom()}, nil) :: no_return()
  def handle_cast({:register_topic, topic}, state) do
    table_name = table_name(topic)
    all_tables = :ets.all()
    unless Enum.any?(all_tables, fn table -> table == table_name end) do
      opts = [:set, :public, :named_table, {:read_concurrency, true}]
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
  @spec handle_cast({:delete, {atom(), String.t | integer()}}, nil)
    :: no_return()
  def handle_cast({:delete, {topic, id}}, state) do
    Ets.delete(table_name(topic), id)
    {:noreply, state}
  end

  @doc false
  @spec handle_call({:save, Event.t}, any(), nil) :: no_return()
  def handle_call({:save, %Event{id: id, topic: topic} = event}, _from, state) do
    Ets.insert(table_name(topic), {id, event})
    {:reply, :ok, state}
  end

  defp table_name(topic),
    do: :"#{@prefix}#{topic}"
end
