defmodule EventBus.Application do
  @moduledoc false

  use Application
  alias EventBus.Manager.{
    Notification,
    Observation,
    Store,
    Subscription,
    Topic
  }

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Topic, [], id: make_ref(), restart: :permanent),
      worker(Subscription, [], id: make_ref(), restart: :permanent),
      worker(Notification, [], id: make_ref(), restart: :permanent),
      worker(Store, [], id: make_ref(), restart: :permanent),
      worker(Observation, [], id: make_ref(), restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: EventBus.Supervisor]
    link = Supervisor.start_link(children, opts)
    register_topics()
    link
  end

  defp register_topics do
    Topic.register_from_config()
  end
end
