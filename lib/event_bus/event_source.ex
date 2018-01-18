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
    end
  end

  @doc """
  Dynamic event builder block with auto initialized_at and occurred_at fields
  """
  defmacro build(params, do: yield) do
    quote do
      initialized_at = System.os_time(:micro_seconds)
      params         = unquote(params)
      source         = Map.get(params, :source,
        String.replace("#{__MODULE__}", "Elixir.", ""))
      {topic, data}  =
      case unquote(yield) do
        {:error, error} ->
          {params[:error_topic] || params[:topic], {:error, error}}
        result ->
          {params[:topic], result}
      end

      %Event{
        id:             params[:id],
        topic:          topic,
        transaction_id: params[:transaction_id],
        data:           data,
        initialized_at: initialized_at,
        occurred_at:    System.os_time(:micro_seconds),
        source:         source,
        ttl:            params[:ttl]
      }
    end
  end

  @doc """
  Dynamic event notifier block with auto initialized_at and occurred_at fields
  """
  defmacro notify(params, do: yield) do
    quote do
      event =
        EventSource.build(unquote(params)) do
          unquote(yield)
        end

      EventBus.notify(event)
      event.data
    end
  end
end
