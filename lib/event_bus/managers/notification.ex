defmodule EventBus.Manager.Notification do
  @moduledoc false

  ###########################################################################
  # Notification is responsible for saving events, creating event watcher and
  # delivering events to listeners.
  ###########################################################################

  use GenServer
  alias EventBus.Model.Event
  alias EventBus.Service.Notification, as: NotificationService

  @app :event_bus
  @backend Application.get_env(@app, :notifier_backend, NotificationService)

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def init(args) do
    {:ok, args}
  end

  @doc """
  Notify event to its listeners
  """
  @spec notify(Event.t()) :: no_return()
  def notify(%Event{} = event) do
    GenServer.cast(__MODULE__, {:notify, event})
  end

  ###########################################################################
  # PRIVATE API
  ###########################################################################

  @doc false
  @spec handle_cast({:notify, Event.t()}, term()) :: no_return()
  def handle_cast({:notify, event}, state) do
    @backend.notify(event)
    {:noreply, state}
  end
end
