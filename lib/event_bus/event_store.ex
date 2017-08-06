defmodule EventBus.EventStore do
  @moduledoc """
  Event Manager
  """

  require Logger
  use GenServer
  alias :ets, as: Ets

  @prefix "eb_es_"

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
  @spec fetch({atom(), String.t}) :: any()
  def fetch({type, key}) do
    case Ets.lookup(table_name(type), key) do
      [{_, data}] -> data
      _ -> nil
    end
  end

  @doc false
  @spec delete({atom(), String.t}) :: no_return()
  def delete({type, key}) do
    GenServer.cast(__MODULE__, {:delete, {type, key}})
  end

  @doc false
  @spec save({atom(), String.t, any()}) :: :ok
  def save({type, key, data}) do
    GenServer.call(__MODULE__, {:save, {type, key, data}})
  end

  @doc false
  def handle_cast({:register_event, name}, state) do
    table_name = table_name(name)
    opts = [:set, :public, :named_table, {:read_concurrency, true}]
    Ets.new(table_name, opts)
    {:noreply, state}
  end
  @doc false
  def handle_cast({:delete, {type, key}}, state) do
    Ets.delete(table_name(type), key)
    {:noreply, state}
  end

  @doc false
  def handle_call({:save, {type, key, data}}, _from, state) do
    Ets.insert(table_name(type), {key, data})
    {:reply, :ok, state}
  end

  defp table_name(type) do
    :"#{@prefix}#{type}"
  end
end
