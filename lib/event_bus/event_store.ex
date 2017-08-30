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
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  @spec register_topic(String.t) :: no_return()
  def register_topic(topic) do
    GenServer.cast(__MODULE__, {:register_topic, topic})
  end

  @doc false
  @spec fetch({atom(), String.t}) :: any()
  def fetch({topic, id}) do
    case Ets.lookup(table_name(topic), id) do
      [{_, %Event{} = event}] -> event
      _ -> nil
    end
  end

  @doc false
  @spec delete({atom(), String.t}) :: no_return()
  def delete({topic, id}) do
    GenServer.cast(__MODULE__, {:delete, {topic, id}})
  end

  @doc false
  @spec save(Event.t) :: :ok
  def save(%Event{} = event) do
    GenServer.call(__MODULE__, {:save, event})
  end

  @doc false
  def handle_cast({:register_topic, topic}, state) do
    table_name = table_name(topic)
    opts = [:set, :public, :named_table, {:read_concurrency, true}]
    Ets.new(table_name, opts)
    {:noreply, state}
  end
  @doc false
  def handle_cast({:delete, {topic, id}}, state) do
    Ets.delete(table_name(topic), id)
    {:noreply, state}
  end

  @doc false
  def handle_call({:save, %Event{id: id, topic: topic} = event}, _from, state) do
    Ets.insert(table_name(topic), {id, event})
    {:reply, :ok, state}
  end

  defp table_name(topic) do
    :"#{@prefix}#{topic}"
  end
end
