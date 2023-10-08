defmodule DependencyTrackerTest do
  use ExUnit.Case
  doctest DependencyTracker

  test "greets the world" do
    assert DependencyTracker.hello() == :world
  end
end
