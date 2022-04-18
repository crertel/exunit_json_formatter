defmodule ExUnitJsonFormatterTest do
  use ExUnit.Case
  # doctest ExUnitJsonFormatter

  test "succeeds" do
    assert true
  end

  test "fails" do
    assert false
  end

  @tag :example_tag
  @tag example_tag_2: :ok
  test "succeeds with tags" do
    assert true
  end
end
