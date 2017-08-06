defmodule EventBus.Application do
  @moduledoc false

  use Application
  alias EventBus.Config
  alias EventBus.EventManager
  alias EventBus.EventStore
  alias EventBus.EventWatcher
  alias EventBus.SubscriptionManager

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(SubscriptionManager, [], id: make_ref(), restart: :permanent),
      worker(EventManager, [], id: make_ref(), restart: :permanent),
      worker(EventStore, [], id: make_ref(), restart: :permanent),
      worker(EventWatcher, [], id: make_ref(), restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: EventBus.Supervisor]
    link = Supervisor.start_link(children, opts)
    register_events()
    link
  end

  defp register_events do
    events = Config.events()
    Enum.each(events, fn event -> register_event(event) end)
  end

  defp register_event(event) do
    EventStore.register_event(event)
    EventWatcher.register_event(event)
  end
end
