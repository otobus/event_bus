defmodule EventBus.Application do
  @moduledoc false

  use Application
  alias EventBus.{Notifier, Store, Watcher, Subscription, Topic}

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Topic, [], id: make_ref(), restart: :permanent),
      worker(Subscription, [], id: make_ref(), restart: :permanent),
      worker(Notifier, [], id: make_ref(), restart: :permanent),
      worker(Store, [], id: make_ref(), restart: :permanent),
      worker(Watcher, [], id: make_ref(), restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: EventBus.Supervisor]
    link = Supervisor.start_link(children, opts)
    Topic.register_from_config()
    link
  end
end
