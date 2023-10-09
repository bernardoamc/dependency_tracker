defmodule DependencyTrackerTest do
  use ExUnit.Case
  doctest DependencyTracker

  alias DependencyTracker.Ruby.PackageDefinition

  test "detects issues between Specification and PackageDefinition" do
    {:ok, package_definition} = PackageDefinition.parse("test/fixtures/ruby/Gemfile.lock")
    specification = DependencyTracker.Specification.new(["aasm"], "https://acme.io/basic/gems/ruby/")

    expected_issues = [
      %{
        specification_url: "https://acme.io/basic/gems/ruby/",
        dependency: "aasm",
        package_definition_url: "https://rubygems.org/"
      }
    ]

    assert DependencyTracker.issues(specification, package_definition) == expected_issues
  end

  test "returns empty list of issues when Specification is empty" do
    {:ok, package_definition} = PackageDefinition.parse("test/fixtures/ruby/Gemfile.lock")
    specification = DependencyTracker.Specification.new()

    assert DependencyTracker.issues(specification, package_definition) == []
  end

  test "returns empty list of issues when specifications are met" do
    {:ok, package_definition} = PackageDefinition.parse("test/fixtures/ruby/Gemfile.lock")
    specification = DependencyTracker.Specification.new(["aasm"], "https://rubygems.org/")

    assert DependencyTracker.issues(specification, package_definition) == []
  end
end
