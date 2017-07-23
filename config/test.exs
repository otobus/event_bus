use Mix.Config

config :event_bus,
  events: [:metrics_received, :metrics_summed]
