defmodule EventBus.Manager.Notification do
  @moduledoc false

  ###########################################################################
  # Notification is responsible for saving events, creating event watcher and
  # delivering events to subscribers.
  ###########################################################################

  use GenServer

  alias EventBus.Model.Event
  alias EventBus.Service.Notification, as: NotificationService

  @typep event :: EventBus.event()

  @backend NotificationService

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def init(args) do
    {:ok, args}
  end

  @doc """
  Notify event to event.topic subscribers in the current node
  """
  @spec notify(event()) :: :ok
  def notify(%Event{} = event) do
    GenServer.cast(__MODULE__, {:notify, event})
  end

  @doc """
  Notify event to event.topic subscribers in the current node, while
  also returning the results of the `process/2` function of each
  subscriber.
  """
  def declare(%Event{} = event) do
    GenServer.call(__MODULE__, {:declare, event})
  end

  ###########################################################################
  # PRIVATE API
  ###########################################################################

  @doc false
  @spec handle_cast({:notify, event()}, term()) :: no_return()
  def handle_cast({:notify, event}, state) do
    @backend.notify(event) # results discarded...
    {:noreply, state}
  end

  def handle_call({:declare, event}, _from, state) do
    {:reply, @backend.notify(event), state}  
  end
end
