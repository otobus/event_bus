defmodule EventBus.Util.RegexTest do
  use ExUnit.Case
  alias EventBus.Util.Regex, as: RegexUtil

  test "superset? should return true when it is superset of given key" do
    assert RegexUtil.superset?(~w(.*), "some")
    assert RegexUtil.superset?(~w(metrics painted), "metrics_received")
  end

  test "superset? should return false when it is not superset of given key" do
    refute RegexUtil.superset?(~w(metrics_sum$), "metrics_summed")
  end
end
