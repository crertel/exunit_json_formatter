defmodule ExunitJsonFormatterTest do
  use ExUnit.Case
  doctest ExunitJsonFormatter

  test "greets the world" do
    assert ExunitJsonFormatter.hello() == :world
  end
end
