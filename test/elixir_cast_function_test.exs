defmodule ElixirCastFunctionTest do
  use ExUnit.Case
  doctest ElixirCastFunction

  test "greets the world" do
    assert ElixirCastFunction.hello() == :world
  end
end
