defmodule EventBus.Model.Event do
  @moduledoc """
  Structure and type for Event model
  """

  defstruct [:id, :transaction_id, :topic, :data]

  @type t :: %__MODULE__{
    id: String.t | integer,
    transaction_id: String.t | integer,
    topic: atom,
    data: any
  }
end
