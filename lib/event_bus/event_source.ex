defmodule EventBus.EventSource do
  @moduledoc """
  Event builder and notifier blocks/yields for EventBus
  """
  alias EventBus.EventSourceImpl

  defmacro __using__(_) do
    quote do
      require EventBus.EventSource

      alias EventBus.EventSource
      alias EventBus.Model.Event
    end
  end

  @doc """
  Dynamic event builder block with auto setters

  It auto sets id, transaction_id, source, ttl, initialized_at and occurred_at
  fields when they are not provided in the params
  """
  defmacro build(params, fun) do
    macro_build(Macro.escape(__CALLER__), params, fun)
  end

  defp macro_build(caller, params, fun) do
    quote do
      EventSourceImpl.build(unquote(caller), unquote(params), unquote(fun))
    end
  end

  @doc """
  Dynamic event emitter block with auto setters

  It auto sets id, transaction_id, source, ttl, initialized_at and occurred_at
  fields when they are not provided in the params
  """
  defmacro notify(params, fun) do
    macro_notify(Macro.escape(__CALLER__), params, fun)
  end

  defp macro_notify(caller, params, fun) do
    quote do
      EventSourceImpl.notify(unquote(caller), unquote(params), unquote(fun))
    end
  end
end

defmodule EventBus.EventSourceImpl do
  @moduledoc false
  alias EventBus.Model.Event
  alias EventBus.Util.Base62
  alias EventBus.Util.MonotonicTime

  @eb_app :event_bus

  @doc false
  def build(caller, params, fun) do
    initialized_at = MonotonicTime.now()
    config = get_config(caller)

    {topic, data} =
      case fun.() do
        {:error, error} ->
          {params[:error_topic] || params[:topic], {:error, error}}

        result ->
          {params[:topic], result}
      end

    id_generator = Map.get(config, :eb_id_gen)
    id = Map.get(params, :id, id_generator.unique_id())

    %Event{
      id: id,
      topic: topic,
      transaction_id: Map.get(params, :transaction_id, id),
      data: data,
      initialized_at: initialized_at,
      occurred_at: MonotonicTime.now(),
      source: Map.get(params, :source, config[:eb_source]),
      ttl: Map.get(params, :ttl, config[:eb_ttl])
    }
  end

  @doc false
  def notify(caller, params, fun) do
    event = build(caller, params, fun)
    EventBus.notify(event)

    event.data
  end

  defp get_config(caller) do
    %{module: module, function: _fun, file: _file, line: _line} = caller

    %{
      eb_app: @eb_app,
      eb_id_gen: Application.get_env(@eb_app, :id_generator, Base62),
      eb_source: String.replace("#{module}", "Elixir.", ""),
      eb_ttl: Application.get_env(@eb_app, :ttl)
    }
  end
end
