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
      %{
        id: make_ref(),
        restart: :permanent,
        start: {Topic, :start_link, []}
      },
      %{
        id: make_ref(),
        restart: :permanent,
        start: {Subscription, :start_link, []}
      },
      %{
        id: make_ref(),
        restart: :permanent,
        start: {Notification, :start_link, []}
      },
      %{
        id: make_ref(),
        restart: :permanent,
        start: {Store, :start_link, []}
      },
      %{
        id: make_ref(),
        restart: :permanent,
        start: {Observation, :start_link, []}
      }
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
