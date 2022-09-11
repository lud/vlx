defmodule Vlx.VLCComTest do
  use ExUnit.Case, async: false

  alias Vlx.VLCCom

  test "connecting to VLC" do
    assert {:ok, com} = VLCCom.connect()
    dbg(com)
  end
end
