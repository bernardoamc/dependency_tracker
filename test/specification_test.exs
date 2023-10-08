defmodule DependencyTracker.SpecificationTest do
  use ExUnit.Case
  doctest DependencyTracker.Specification

  alias DependencyTracker.Specification

  test "new with no arguments creates an empty Specification" do
    assert Specification.new() == %Specification{}
  end

  test "new with a list of dependencies creates a Specification with those dependencies" do
    assert Specification.new(["aasm"], "https://rubygems.org/") ==
      %Specification{rules: %{"aasm" => "https://rubygems.org/"}}
  end

  test "add_dependency adds a dependency to a Specification when it is not present" do
    assert Specification.add_dependency(Specification.new(), "aasm", "https://rubygems.org/") ==
      {:ok, %Specification{rules: %{"aasm" => "https://rubygems.org/"}}}
  end

  test "add_dependency returns error when dependency already exists" do
    specification = Specification.new(["aasm"], "https://rubygems.org/")

    assert Specification.add_dependency(specification, "aasm", "https://acme.io/basic/gems/ruby/") ==
      {:error, :dependency_already_exists}
  end

  test "valid_dependency? returns :valid_dependency when dependency exists and remote URL matches" do
    specification = Specification.new(["aasm"], "https://rubygems.org/")

    assert Specification.valid_dependency?(specification, "aasm", "https://rubygems.org/") ==
      {:ok, :valid_dependency}
  end

  test "valid_dependency? returns :not_found when dependency does not exist" do
    specification = Specification.new(["aasm"], "https://rubygems.org/")

    assert Specification.valid_dependency?(specification, "faker", "https://rubygems.org/") ==
      {:ok, :not_found}
  end

  test "valid_dependency? returns {:error, expected_url} when dependency exists and remote URL does not match" do
    specification = Specification.new(["aasm"], "https://rubygems.org/")

    assert Specification.valid_dependency?(specification, "aasm", "https://acme.io/basic/gems/ruby/") ==
      {:error, "https://rubygems.org/"}
  end
end
