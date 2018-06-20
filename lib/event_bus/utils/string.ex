defmodule EventBus.Util.String do
  @moduledoc false
  # String util for event bus

  @doc """
  Generates random id(Most probably unique id)
  """
  @spec unique_id() :: String.t()
  def unique_id do
    Base.url_encode64(:crypto.strong_rand_bytes(7), padding: false)
  end
end
