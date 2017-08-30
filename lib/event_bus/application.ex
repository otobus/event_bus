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
    register_topics()
    link
  end

  defp register_topics do
    topics = Config.topics()
    Enum.each(topics, fn topic -> register_topic(topic) end)
  end

  defp register_topic(topic) do
    EventStore.register_topic(topic)
    EventWatcher.register_topic(topic)
  end
end
