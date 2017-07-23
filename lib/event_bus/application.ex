defmodule EventBus.Application do
  @moduledoc false

  use Application
  alias EventBus.EventManager
  alias EventBus.SubscriptionManager

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(SubscriptionManager, [], id: make_ref(), restart: :permanent),
      worker(EventManager, [], id: make_ref(), restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: EventBus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
