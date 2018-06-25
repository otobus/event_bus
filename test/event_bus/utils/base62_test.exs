defmodule EventBus.Util.Base62Test do
  use ExUnit.Case
  alias EventBus.Util.Base62

  test ".encode" do
    assert "0" == Base62.encode(0)
    assert "z" == Base62.encode(61)
    assert "10" == Base62.encode(62)
    assert "1p0uwg6tOzJ" == Base62.encode(1529891323138833953)
  end

  test ".unique_id" do
    refute Base62.unique_id() == Base62.unique_id()
  end

  test ".unique_id length" do
    assert 16 == String.length(Base62.unique_id())
  end
end
