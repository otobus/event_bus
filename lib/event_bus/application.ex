defmodule EventBus.Application do
  @moduledoc false

  use Application
  alias EventBus.EventManager
  alias EventBus.EventStore
  alias EventBus.EventWatcher
  alias EventBus.SubscriptionManager
  alias EventBus.TopicManager

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(TopicManager, [], id: make_ref(), restart: :permanent),
      worker(SubscriptionManager, [], id: make_ref(), restart: :permanent),
      worker(EventManager, [], id: make_ref(), restart: :permanent),
      worker(EventStore, [], id: make_ref(), restart: :permanent),
      worker(EventWatcher, [], id: make_ref(), restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: EventBus.Supervisor]
    link = Supervisor.start_link(children, opts)
    TopicManager.register_from_config()
    link
  end
end
