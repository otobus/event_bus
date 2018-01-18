defmodule EventBus.Notifier do
  @moduledoc false

  ###########################################################################
  # Notifier is responsible for saving events, creating event watcher and
  # delivering events to listeners.
  ###########################################################################

  use GenServer
  alias EventBus.Model.Event

  @backend Application.get_env(
             :event_bus,
             :notifier_backend,
             EventBus.Service.Notifier
           )

  @doc false
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  def init(args),
    do: {:ok, args}

  @doc """
  Notify event to its listeners
  """
  @spec notify(Event.t()) :: no_return()
  def notify(%Event{} = event),
    do: GenServer.cast(__MODULE__, {:notify, event})

  ###########################################################################
  # PRIVATE API
  ###########################################################################

  @doc false
  @spec handle_cast({:notify, Event.t()}, nil) :: no_return()
  def handle_cast({:notify, event}, state) do
    @backend.notify(event)
    {:noreply, state}
  end
end
