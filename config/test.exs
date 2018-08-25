use Mix.Config

config :event_bus,
  topics: [:metrics_received, :metrics_summed],
  ttl: 30_000_000,
  time_unit: :microsecond,
  id_generator: EventBus.Util.String
