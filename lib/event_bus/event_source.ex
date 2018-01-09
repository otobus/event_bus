defmodule EventBus.EventSource do
  @moduledoc """
  Event builder and notifier blocks/yields for EventBus
  """

  alias EventBus.Model.Event

  defmacro __using__(_) do
    quote do
      require EventBus.EventSource
      alias EventBus.EventSource
      alias EventBus.Model.Event
    end
  end

  @doc """
  Dynamic event builder block with auto initialized_at and occurred_at fields
  """
  defmacro build(params, do: yield) do
    quote do
      initialized_at = System.os_time(:milli_seconds)
      params         = unquote(params)
      data           = unquote(yield)

      %Event{
        id:             params[:id],
        topic:          params[:topic],
        transaction_id: params[:transaction_id],
        data:           data,
        initialized_at: initialized_at,
        occurred_at:    System.os_time(:milli_seconds),
        source:         params[:source] || "#{__MODULE__}",
        ttl:            params[:ttl]
      }
    end
  end

  @doc """
  Dynamic event notifier block with auto initialized_at and occurred_at fields
  """
  defmacro notify(params, do: yield) do
    quote do
      initialized_at = System.os_time(:milli_seconds)
      params         = unquote(params)
      data           = unquote(yield)
      event          = %Event{
        id:             params[:id],
        topic:          params[:topic],
        transaction_id: params[:transaction_id],
        data:           data,
        initialized_at: initialized_at,
        occurred_at:    System.os_time(:milli_seconds),
        source:         params[:source] || "#{__MODULE__}",
        ttl:            params[:ttl]
      }

      EventBus.notify(event)
      data
    end
  end
end
