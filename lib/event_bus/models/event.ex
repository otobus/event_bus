defmodule EventBus.Model.Event do
  @moduledoc """
  Structure and type for Event model
  """

  @enforce_keys [:id, :topic, :data]

  defstruct [:id, :transaction_id, :topic, :data, :occurred_at, :ttl]

  @type t :: %__MODULE__{
    id: String.t | integer,
    transaction_id: String.t | integer,
    topic: atom,
    data: any,
    occurred_at: integer,
    ttl: integer
  }
end
