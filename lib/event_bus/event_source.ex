defmodule EventBus.EventSource do
  @moduledoc """
  Event builder and notifier blocks/yields for EventBus
  """

  alias EventBus.Model.Event
  alias __MODULE__

  defmacro __using__(_) do
    quote do
      require EventBus.EventSource

      alias EventBus.EventSource
      alias EventBus.Model.Event
      alias EventBus.Util.Base62

      @eb_app :event_bus
      @eb_id_gen Application.get_env(@eb_app, :id_generator, Base62)
      @eb_source String.replace("#{__MODULE__}", "Elixir.", "")
      @eb_time_unit Application.get_env(@eb_app, :time_unit, :microsecond)
      @eb_ttl Application.get_env(@eb_app, :ttl)
    end
  end

  @doc """
  Dynamic event builder block with auto setting source, initialized_at and
  occurred_at fields in microseconds
  """
  defmacro build(params, do: yield) do
    quote do
      started_at = System.monotonic_time(@eb_time_unit)
      initialized_at = System.os_time(@eb_time_unit)
      params = unquote(params)

      {topic, data} =
        case unquote(yield) do
          {:error, error} ->
            {params[:error_topic] || params[:topic], {:error, error}}

          result ->
            {params[:topic], result}
        end

      id = Map.get(params, :id, @eb_id_gen.unique_id())
      time_spent = System.monotonic_time(@eb_time_unit) - started_at

      %Event{
        id: id,
        topic: topic,
        transaction_id: Map.get(params, :transaction_id, id),
        data: data,
        initialized_at: initialized_at,
        occurred_at: initialized_at + time_spent,
        source: Map.get(params, :source, @eb_source),
        ttl: Map.get(params, :ttl, @eb_ttl)
      }
    end
  end

  @doc """
  Dynamic event notifier block with auto setting source, initialized_at and
  occurred_at fields in microseconds
  """
  defmacro notify(params, do: yield) do
    quote do
      event =
        EventSource.build unquote(params) do
          unquote(yield)
        end

      EventBus.notify(event)
      event.data
    end
  end
end
