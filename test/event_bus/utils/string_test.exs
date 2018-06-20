defmodule EventBus.Util.StringTest do
  use ExUnit.Case
  alias EventBus.Util.String, as: StringUtil

  test "generates unique_id" do
    refute StringUtil.unique_id() == StringUtil.unique_id()
  end
end
