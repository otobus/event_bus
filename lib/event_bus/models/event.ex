defmodule EventBus.Model.Event do
  @moduledoc """
  Structure and type for Event model
  """

  alias __MODULE__

  @enforce_keys [:id, :topic, :data]

  defstruct [
    :id,
    :transaction_id,
    :topic,
    :data,
    :initialized_at,
    :occurred_at,
    :ttl
  ]

  @typedoc """
  Defines the Event struct.

  * :id - Identifier
  * :transaction_id - Transaction identifier, if event belongs to a transaction
  * :topic - Topic name
  * :data - Context
  * :initialized_at - When the process initialized to generate this event
  * :occurred_at - When it is occurred
  * :ttl - Time to live value
  """
  @type t :: %__MODULE__{
    id: String.t | integer,
    transaction_id: String.t | integer,
    topic: atom,
    data: any,
    initialized_at: integer,
    occurred_at: integer,
    ttl: integer
  }

  @doc """
  Duration of the event, and simple answer of how long does it take to generate
  this event
  """
  def duration(%__MODULE__{initialized_at: initialized_at,
    occurred_at: occurred_at})
    when is_integer(initialized_at) and is_integer(occurred_at) do
    occurred_at - initialized_at
  end
  def duration(_),
    do: 0

  @doc """
  Dynamic event builder block with auto initialized_at and occurred_at fields
  """
  defmacro build(id, topic, transaction_id \\ nil, ttl \\ nil, do: yield) do
    quote do
      initialized_at = System.os_time(:milli_seconds)
      data = unquote(yield)
      %Event{
        id: unquote(id),
        topic: unquote(topic),
        transaction_id: unquote(transaction_id),
        data: data,
        initialized_at: initialized_at,
        occurred_at: System.os_time(:milli_seconds),
        ttl: unquote(ttl)
      }
    end
  end

  @doc """
  Dynamic event notifier block with auto initialized_at and occurred_at fields
  """
  defmacro notify(id, topic, transaction_id \\ nil, ttl \\ nil, do: yield) do
    quote do
      initialized_at = System.os_time(:milli_seconds)
      data = unquote(yield)
      event = %Event{
        id: unquote(id),
        topic: unquote(topic),
        transaction_id: unquote(transaction_id),
        data: data,
        initialized_at: initialized_at,
        occurred_at: System.os_time(:milli_seconds),
        ttl: unquote(ttl)
      }
      EventBus.notify(event)
      data
    end
  end
end
