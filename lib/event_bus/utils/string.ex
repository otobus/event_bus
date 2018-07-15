defmodule EventBus.Util.String do
  @moduledoc false
  # String util for event bus
  # Warning: This module is deprecated will be removed in next major release

  alias EventBus.Util.Base62

  @spec unique_id() :: String.t()
  defdelegate unique_id,
    to: Base62
end
