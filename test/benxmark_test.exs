defmodule BenxmarkTest do
  use ExUnit.Case
  doctest Benxmark

  test "greets the world" do
    assert Benxmark.hello() == :world
  end
end
